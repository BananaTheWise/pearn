import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Central GitHub Contents API service.
///
/// All GitHub HTTP requests flow through this class. It handles both
/// read operations (course content) and write operations required by the
/// Tutor → Admin submission workflow (branches, commits, pull requests).
///
/// The personal access token is injected via the `GITHUB_TOKEN` environment
/// variable and is **never** logged.
class GithubService {
  // ---------------------------------------------------------------------------
  // Configuration (from build environment – NEVER LOGGED)
  // ---------------------------------------------------------------------------
  static final String _owner = const String.fromEnvironment('GITHUB_OWNER');
  static final String _repo = const String.fromEnvironment('GITHUB_REPO');
  static final String _token = const String.fromEnvironment('GITHUB_TOKEN');

  late final Dio _dio;

  GithubService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.github.com',
      headers: {
        'Authorization': 'token $_token',
        'Accept': 'application/vnd.github.v3+json',
      },
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    if (_owner.isEmpty || _repo.isEmpty || _token.isEmpty) {
      debugPrint(
        '[WARNING][GITHUB] GitHub configuration is incomplete. '
        'Set GITHUB_OWNER, GITHUB_REPO, and GITHUB_TOKEN environment variables.',
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Public API – read operations (existing functionality)
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns a list of course folder names from the repository's `courses` directory.
  Future<List<String>> listCourseFolders() async {
    debugPrint('[GITHUB] Loading course folders');
    debugPrint('[GITHUB] Requesting /contents/courses');

    const path = '/repos/$_owner/$_repo/contents/courses';
    final response = await _getWithRetry<dynamic>(path);

    final List<dynamic> items = response.data as List<dynamic>;
    final folders = items
        .whereType<Map<String, dynamic>>()
        .where((item) => item['type'] == 'dir')
        .map((item) => item['name'] as String)
        .toList();

    debugPrint('[GITHUB] Course folders received: ${folders.length}');
    debugPrint('[GITHUB] Course folder loading completed');
    return folders;
  }

  /// Fetches a JSON file from the repository and returns the decoded map.
  Future<Map<String, dynamic>> fetchJson(String path) async {
    debugPrint('[GITHUB] Fetching JSON: $path');
    final apiPath = '/repos/$_owner/$_repo/contents/$path';
    final response = await _getWithRetry<Map<String, dynamic>>(apiPath);
    final fileMap = response.data!;
    final contentEncoded = fileMap['content'] as String?;
    final encoding = fileMap['encoding'] as String?;

    if (contentEncoded == null || encoding != 'base64') {
      throw Exception('Unexpected file encoding for $path');
    }

    debugPrint('[GITHUB] Decoding JSON: $path');
    final decodedString = _decodeBase64Utf8(contentEncoded, path);
    try {
      final json = jsonDecode(decodedString) as Map<String, dynamic>;
      debugPrint('[GITHUB] JSON loaded successfully');
      return json;
    } catch (e) {
      debugPrint('[ERROR][GITHUB] Invalid JSON in $path');
      rethrow;
    }
  }

  /// Fetches a Markdown file and returns its content as a plain string.
  Future<String> fetchMarkdown(String path) async {
    debugPrint('[GITHUB] Fetching Markdown: $path');
    final apiPath = '/repos/$_owner/$_repo/contents/$path';
    final response = await _getWithRetry<Map<String, dynamic>>(apiPath);
    final fileMap = response.data!;
    final contentEncoded = fileMap['content'] as String?;
    final encoding = fileMap['encoding'] as String?;

    if (contentEncoded == null || encoding != 'base64') {
      throw Exception('Unexpected file encoding for $path');
    }

    return _decodeBase64Utf8(contentEncoded, path);
  }

  /// Returns the SHA of the latest commit that modified the given [path].
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
  // Public API – write operations (tutor/admin workflow)
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a new branch from [baseBranch] and returns its HEAD SHA.
  Future<String> createBranch(String baseBranch, String newBranchName) async {
    debugPrint('[GITHUB] Creating branch: $newBranchName from $baseBranch');

    try {
      // 1. Get the SHA of the base branch
      final refResponse = await _dio.get<Map<String, dynamic>>(
        '/repos/$_owner/$_repo/git/ref/heads/$baseBranch',
      );
      final sha = refResponse.data!['object']['sha'] as String;

      // 2. Create the new reference
      final response = await _dio.post<Map<String, dynamic>>(
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
  /// [content] must be the **raw** file content; it will be Base64-encoded internally.
  Future<void> createOrUpdateFile(
    String branch,
    String path,
    String content,
    String commitMessage,
  ) async {
    debugPrint('[GITHUB] Writing file: $path on branch $branch');

    // Check if file already exists to obtain its SHA for update
    String? existingSha;
    try {
      final existing = await _dio.get<Map<String, dynamic>>(
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

    await _dio.put(
      '/repos/$_owner/$_repo/contents/$path',
      data: data,
    );
    debugPrint('[GITHUB] File committed successfully');
  }

  /// Opens a pull request from [headBranch] to [baseBranch].
  /// Returns the HTML URL of the created PR.
  Future<String> createPullRequest(
    String headBranch,
    String baseBranch,
    String title,
    String body,
  ) async {
    debugPrint('[GITHUB] Creating pull request: $headBranch → $baseBranch');

    final response = await _dio.post<Map<String, dynamic>>(
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
  /// Returns `true` if the merge was successful (status 200).
  Future<bool> mergePullRequest(int pullNumber) async {
    debugPrint('[GITHUB] Merging PR #$pullNumber');

    try {
      await _dio.put(
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
      await _dio.patch(
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
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Performs a GET request with built-in retry logic for 5xx and timeouts.
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
        final response = await _dio.get<T>(
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

  String _decodeBase64Utf8(String base64String, String pathForLog) {
    try {
      final bytes = base64.decode(base64String);
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('[ERROR][GITHUB] Base64 decoding failed for $pathForLog');
      rethrow;
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