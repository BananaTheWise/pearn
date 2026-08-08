import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Central GitHub content service.
///
/// READS (course catalog, chapters, lessons) go through jsDelivr's public
/// CDN (https://cdn.jsdelivr.net + https://data.jsdelivr.com), which mirrors
/// public GitHub repos with NO rate limit for reasonable use. This avoids
/// GitHub's own unauthenticated cap of 60 requests/hour per IP, which is
/// shared across every user of the app on the same network and was causing
/// the catalog to fail to load under normal use.
///
/// WRITES (tutor submission workflow: branches, commits, pull requests,
/// merges) still go through the real GitHub API, since jsDelivr is
/// read-only. Writes are infrequent (tutors submitting/updating courses)
/// and authenticated via [GITHUB_TOKEN], so GitHub's normal 5,000/hour
/// authenticated limit is not a concern there.
///
/// The personal access token is injected via the `GITHUB_TOKEN` environment
/// variable and is **never** logged.
class GithubService {
  // ---------------------------------------------------------------------------
  // Configuration (from build environment – NEVER LOGGED)
  // ---------------------------------------------------------------------------
  static const String _owner = String.fromEnvironment('GITHUB_OWNER');
  static const String _repo = String.fromEnvironment('GITHUB_REPO');
  static const String _token = String.fromEnvironment('GITHUB_TOKEN');

  /// Branch (or tag/commit) that jsDelivr serves content from.
  /// Change this if your default branch isn't "main".
  static const String _branch = 'main';

  late final Dio _api; // authenticated GitHub API, for writes
  late final Dio _cdn; // jsDelivr raw content CDN, for reads
  late final Dio _cdnData; // jsDelivr metadata/tree API, for listing

  GithubService() {
    _api = Dio(
      BaseOptions(
        baseUrl: 'https://api.github.com',
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
        },
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    _cdn = Dio(
      BaseOptions(
        baseUrl: 'https://cdn.jsdelivr.net/gh/$_owner/$_repo@$_branch',
        responseType: ResponseType.plain,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    _cdnData = Dio(
      BaseOptions(
        baseUrl: 'https://data.jsdelivr.com/v1/packages/gh/$_owner/$_repo@$_branch',
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (_owner.isEmpty || _repo.isEmpty) {
      debugPrint(
        '[WARNING][GITHUB] GitHub configuration is incomplete. '
        'Set GITHUB_OWNER, GITHUB_REPO, and GITHUB_TOKEN environment variables.',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Public API – read operations (via jsDelivr, effectively unlimited)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a list of course folder names from the repository's `courses` directory.
  Future<List<String>> listCourseFolders() async {
    debugPrint('[GITHUB][CDN] Loading course folders');

    final tree = await _getTree();
    final coursesDir = _findDirectory(tree, 'courses');

    if (coursesDir == null) {
      debugPrint('[GITHUB][CDN] No courses directory found');
      return [];
    }

    final files = coursesDir['files'] as List<dynamic>? ?? [];
    final folders = files
        .whereType<Map<String, dynamic>>()
        .where((item) => item.containsKey('files')) // directories have 'files'
        .map((item) => item['name'] as String)
        .toList();

    debugPrint('[GITHUB][CDN] Course folders received: ${folders.length}');
    return folders;
  }

  /// Fetches a JSON file from the repository and returns the decoded map.
  Future<Map<String, dynamic>> fetchJson(String path) async {
    debugPrint('[GITHUB][CDN] Fetching JSON: $path');
    final raw = await _getRaw(path);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      debugPrint('[GITHUB][CDN] JSON loaded successfully');
      return json;
    } catch (e) {
      debugPrint('[ERROR][GITHUB][CDN] Invalid JSON in $path');
      rethrow;
    }
  }

  /// Fetches a Markdown file and returns its content as a plain string.
  Future<String> fetchMarkdown(String path) async {
    debugPrint('[GITHUB][CDN] Fetching Markdown: $path');
    return _getRaw(path);
  }

  /// Returns the SHA of the latest commit that modified the given [path].
  ///
  /// This still uses the authenticated GitHub API (jsDelivr has no commit
  /// history endpoint). Low-frequency, admin/tutor-workflow only.
  Future<String> getLatestCommitSha(String path) async {
    debugPrint('[GITHUB] Getting latest commit SHA for $path');
    const apiPath = '/repos/$_owner/$_repo/commits';
    final queryParams = {'path': path, 'per_page': 1};
    final response = await _getWithRetry<List<dynamic>>(
      apiPath,
      queryParameters: queryParams,
    );
    final commits = response.data!;
    if (commits.isEmpty) {
      throw Exception('No commits found for $path');
    }
    return commits.first['sha'] as String;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Public API – write operations (tutor/admin workflow, authenticated)
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a new branch from [baseBranch] and returns its HEAD SHA.
  Future<String> createBranch(String baseBranch, String newBranchName) async {
    debugPrint('[GITHUB] Creating branch: $newBranchName from $baseBranch');

    try {
      final refResponse = await _api.get<Map<String, dynamic>>(
        '/repos/$_owner/$_repo/git/ref/heads/$baseBranch',
      );
      final sha = refResponse.data!['object']['sha'] as String;

      final response = await _api.post<Map<String, dynamic>>(
        '/repos/$_owner/$_repo/git/refs',
        data: {
          'ref': 'refs/heads/$newBranchName',
          'sha': sha,
        },
      );

      final newSha = response.data!['object']['sha'] as String;
      debugPrint('[GITHUB] Branch created: $newBranchName (SHA: $newSha)');
      return newSha;
    } on DioException catch (e) {
      debugPrint('[ERROR][GITHUB] Branch creation failed');
      debugPrint('Path: $newBranchName  Reason: ${e.message}');
      rethrow;
    }
  }

  /// Creates or updates a file in the given [branch].
  Future<void> createOrUpdateFile(
    String branch,
    String path,
    String content,
    String commitMessage,
  ) async {
    debugPrint('[GITHUB] Writing file: $path on branch $branch');

    String? existingSha;
    try {
      final existing = await _api.get<Map<String, dynamic>>(
        '/repos/$_owner/$_repo/contents/$path?ref=$branch',
      );
      existingSha = existing.data!['sha'] as String?;
    } catch (_) {
      // File doesn't exist – that's fine
    }

    final encodedContent = base64Encode(utf8.encode(content));
    final data = {
      'message': commitMessage,
      'content': encodedContent,
      'branch': branch,
      if (existingSha != null) 'sha': existingSha,
    };

    await _api.put(
      '/repos/$_owner/$_repo/contents/$path',
      data: data,
    );
    debugPrint('[GITHUB] File committed successfully');
  }

  /// Opens a pull request from [headBranch] to [baseBranch].
  Future<String> createPullRequest(
    String headBranch,
    String baseBranch,
    String title,
    String body,
  ) async {
    debugPrint('[GITHUB] Creating pull request: $headBranch → $baseBranch');

    final response = await _api.post<Map<String, dynamic>>(
      '/repos/$_owner/$_repo/pulls',
      data: {
        'title': title,
        'body': body,
        'head': headBranch,
        'base': baseBranch,
      },
    );

    final htmlUrl = response.data!['html_url'] as String;
    debugPrint('[GITHUB] Pull Request created: $htmlUrl');
    return htmlUrl;
  }

  /// Merges a pull request identified by its [pullNumber].
  Future<bool> mergePullRequest(int pullNumber) async {
    debugPrint('[GITHUB] Merging PR #$pullNumber');

    try {
      await _api.put(
        '/repos/$_owner/$_repo/pulls/$pullNumber/merge',
        data: {'merge_method': 'merge'},
      );
      debugPrint('[GITHUB] Pull Request #$pullNumber merged successfully');
      return true;
    } on DioException catch (e) {
      debugPrint('[ERROR][GITHUB] Merge failed for PR #$pullNumber');
      if (e.response != null) {
        debugPrint('Status: ${e.response!.statusCode}');
      }
      rethrow;
    }
  }

  /// Closes a pull request without merging.
  Future<void> closePullRequest(int pullNumber) async {
    debugPrint('[GITHUB] Closing PR #$pullNumber');

    try {
      await _api.patch(
        '/repos/$_owner/$_repo/pulls/$pullNumber',
        data: {'state': 'closed'},
      );
      debugPrint('[GITHUB] PR #$pullNumber closed');
    } on DioException catch (e) {
      debugPrint('[ERROR][GITHUB] Failed to close PR #$pullNumber');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers – jsDelivr reads
  // ──────────────────────────────────────────────────────────────────────────

  Map<String, dynamic>? _cachedTree;

  /// Fetches (and caches in-memory) the full repo file tree from jsDelivr.
  Future<Map<String, dynamic>> _getTree() async {
    if (_cachedTree != null) return _cachedTree!;

    debugPrint('[GITHUB][CDN] Fetching repo tree');
    final response = await _cdnData.get<Map<String, dynamic>>('');
    _cachedTree = response.data!;
    return _cachedTree!;
  }

  /// Walks the jsDelivr tree looking for a top-level directory by name.
  /// (Extend this if you ever need nested directory lookup beyond one level.)
  Map<String, dynamic>? _findDirectory(
    Map<String, dynamic> tree,
    String name,
  ) {
    final files = tree['files'] as List<dynamic>? ?? [];
    for (final item in files) {
      if (item is Map<String, dynamic> &&
          item['name'] == name &&
          item.containsKey('files')) {
        return item;
      }
    }
    return null;
  }

  /// Fetches raw file content directly from the jsDelivr CDN.
  Future<String> _getRaw(String path) async {
    final response = await _cdnWithRetry<String>('/$path');
    return response.data ?? '';
  }

  Future<Response<T>> _cdnWithRetry<T>(String path) async {
    debugPrint('[GITHUB][CDN] GET $path');
    const maxRetries = 2;
    int attempt = 0;

    while (true) {
      attempt++;
      try {
        final response = await _cdn.get<T>(path);
        debugPrint('[GITHUB][CDN] Request succeeded');
        return response;
      } on DioException catch (e) {
        final shouldRetry = _shouldRetry(e) && attempt <= maxRetries;
        if (shouldRetry) {
          debugPrint('[GITHUB][CDN] Request failed, retrying');
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        debugPrint('[ERROR][GITHUB][CDN] Request failed');
        debugPrint('Path: $path');
        debugPrint('Reason: ${e.message ?? e.type.name}');
        rethrow;
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers – authenticated GitHub API (writes)
  // ──────────────────────────────────────────────────────────────────────────

  Future<Response<T>> _getWithRetry<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    debugPrint('[GITHUB] GET $path');
    const maxRetries = 2;
    int attempt = 0;

    while (true) {
      attempt++;
      debugPrint('[GITHUB] Attempt $attempt');

      try {
        final response = await _api.get<T>(
          path,
          queryParameters: queryParameters,
        );
        debugPrint('[GITHUB] Request succeeded');
        return response;
      } on DioException catch (e) {
        final shouldRetry = _shouldRetry(e) && attempt <= maxRetries;
        if (shouldRetry) {
          debugPrint('[GITHUB] Request failed');
          debugPrint('[GITHUB] Retrying');
          await Future<void>.delayed(const Duration(seconds: 1));
          continue;
        }
        debugPrint('[ERROR][GITHUB] Request failed');
        debugPrint('Path: $path');
        debugPrint('Reason: ${e.message ?? e.type.name}');
        rethrow;
      } catch (e) {
        debugPrint('[ERROR][GITHUB] Unexpected error');
        debugPrint('Path: $path');
        debugPrint('Reason: $e');
        rethrow;
      }
    }
  }

  bool _shouldRetry(DioException error) {
    if (error.response != null && error.response!.statusCode! >= 500) {
      return true;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      default:
        return false;
    }
  }
}