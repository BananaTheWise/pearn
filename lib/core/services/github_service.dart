  import 'dart:convert';

  import 'package:dio/dio.dart';
  import 'package:flutter/foundation.dart';

  /// Central GitHub content service for Pearn.
  ///
  /// READS:
  ///   Public course content is loaded from jsDelivr using an EXACT
  ///   Git commit SHA.
  ///
  /// WRITES:
  ///   Tutor/admin GitHub operations use the authenticated GitHub API.
  ///
  /// IMPORTANT:
  ///   We NEVER use:
  ///
  ///       https://cdn.jsdelivr.net/gh/owner/repo@main/...
  ///
  ///   for course content.
  ///
  ///   Instead we:
  ///
  ///       1. Ask GitHub for the latest main commit SHA.
  ///       2. Build a jsDelivr URL using that exact SHA.
  ///       3. Download the file from that immutable commit.
  ///
  ///   This prevents stale branch-alias CDN content from being used.
  ///
  /// SECURITY WARNING:
  ///   GITHUB_TOKEN must NOT be shipped inside a production Flutter app.
  ///   GitHub write operations should eventually be moved to a backend
  ///   such as a Supabase Edge Function.
  ///
  /// Configuration:
  ///
  ///   --dart-define=GITHUB_OWNER=your-owner
  ///   --dart-define=GITHUB_REPO=your-repository
  ///   --dart-define=GITHUB_TOKEN=your-token
  class GithubService {
    // =========================================================================
    // CONFIGURATION
    // =========================================================================

    static const String _owner = String.fromEnvironment(
      'GITHUB_OWNER',
    );

    static const String _repo = String.fromEnvironment(
      'GITHUB_REPO',
    );

    static const String _token = String.fromEnvironment(
      'GITHUB_TOKEN',
    );

    static const String _branch = 'main';

    late final Dio _api;

    GithubService() {
      // =======================================================================
      // GITHUB API
      // =======================================================================

      _api = Dio(
        BaseOptions(
          baseUrl: 'https://api.github.com',
          headers: {
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
            if (_token.isNotEmpty)
              'Authorization': 'Bearer $_token',
          },
          responseType: ResponseType.json,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      // =======================================================================
      // CONFIGURATION CHECK
      // =======================================================================

      if (_owner.isEmpty || _repo.isEmpty) {
        debugPrint(
          '[WARNING][GITHUB] GitHub configuration is incomplete.',
        );

        debugPrint(
          '[WARNING][GITHUB] '
          'Set GITHUB_OWNER and GITHUB_REPO.',
        );
      }

      debugPrint(
        '[GITHUB] Repository: $_owner/$_repo',
      );

      debugPrint(
        '[GITHUB] Branch: $_branch',
      );

      if (_token.isEmpty) {
        debugPrint(
          '[GITHUB] No GitHub token configured.',
        );

        debugPrint(
          '[GITHUB] Public READ operations will still work.',
        );
      }
    }

    // =========================================================================
    // PUBLIC READ API
    // =========================================================================

    /// Returns the names of course folders inside:
    ///
    ///     courses/
    ///
    /// Example:
    ///
    ///     courses/
    ///       rust/
    ///       sqlite/
    ///       dart/
    ///
    /// This uses the GitHub Git Tree API rather than jsDelivr metadata.
    Future<List<String>> listCourseFolders() async {
      debugPrint(
        '[GITHUB] Loading course folders...',
      );

      try {
        final sha = await _getLatestMainSha();

        debugPrint(
          '[GITHUB] Reading repository tree at SHA: $sha',
        );

        final response =
            await _getWithRetry<Map<String, dynamic>>(
          '/repos/$_owner/$_repo/git/trees/$sha',
          queryParameters: {
            'recursive': '1',
          },
        );

        final tree = response.data;

        if (tree == null) {
          throw Exception(
            'Empty GitHub tree response.',
          );
        }

        final treeItems =
            tree['tree'] as List<dynamic>? ?? [];

        final courses = <String>{};

        for (final item in treeItems) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final path = item['path'] as String?;
          final type = item['type'] as String?;

          if (path == null || type == null) {
            continue;
          }

          // We only care about paths immediately inside courses/.
          //
          // courses/rust/course.json
          // courses/sqlite/course.json
          //
          // => rust, sqlite

          if (!path.startsWith('courses/')) {
            continue;
          }

          final relativePath =
              path.substring('courses/'.length);

          if (relativePath.isEmpty) {
            continue;
          }

          final parts = relativePath.split('/');

          if (parts.length >= 2) {
            courses.add(parts.first);
          }
        }

        final result = courses.toList()..sort();

        debugPrint(
          '[GITHUB] Course folders received: ${result.length}',
        );

        debugPrint(
          '[GITHUB] Courses: $result',
        );

        return result;
      } catch (e) {
        debugPrint(
          '[ERROR][GITHUB] '
          'Failed to load course folders: $e',
        );

        rethrow;
      }
    }

    // =========================================================================
    // FETCH JSON
    // =========================================================================

    /// Fetches and decodes a JSON file from the latest main commit.
    ///
    /// Example:
    ///
    ///     fetchJson('courses/rust/course.json')
    ///
    /// The request will internally become:
    ///
    ///     https://cdn.jsdelivr.net/gh/owner/repo@EXACT_SHA/...
    Future<Map<String, dynamic>> fetchJson(
      String path,
    ) async {
      debugPrint(
        '[GITHUB][CDN] Fetching JSON: $path',
      );

      try {
        final raw = await _getRaw(path);

        if (raw.trim().isEmpty) {
          throw FormatException(
            'Empty response for $path',
          );
        }

        final decoded = jsonDecode(raw);

        if (decoded is! Map<String, dynamic>) {
          throw FormatException(
            'Expected JSON object in $path',
          );
        }

        debugPrint(
          '[GITHUB][CDN] JSON loaded successfully: $path',
        );

        return decoded;
      } catch (e) {
        debugPrint(
          '[ERROR][GITHUB][CDN] '
          'Failed to load JSON: $path',
        );

        debugPrint(
          '[ERROR][GITHUB][CDN] Reason: $e',
        );

        rethrow;
      }
    }

    // =========================================================================
    // FETCH MARKDOWN
    // =========================================================================

    /// Fetches a Markdown/text file from the latest main commit.
    Future<String> fetchMarkdown(
      String path,
    ) async {
      debugPrint(
        '[GITHUB][CDN] Fetching Markdown: $path',
      );

      try {
        return await _getRaw(path);
      } catch (e) {
        debugPrint(
          '[ERROR][GITHUB][CDN] '
          'Failed to load Markdown: $path',
        );

        rethrow;
      }
    }

    // =========================================================================
    // GET LATEST COMMIT SHA FOR A FILE
    // =========================================================================

    /// Returns the latest commit SHA that changed [path].
    ///
    /// This is useful if you need to determine whether one particular
    /// course file changed.
    Future<String> getLatestCommitSha(
      String path,
    ) async {
      debugPrint(
        '[GITHUB] Getting latest commit SHA for $path',
      );

      final response =
          await _getWithRetry<List<dynamic>>(
        '/repos/$_owner/$_repo/commits',
        queryParameters: {
          'path': path,
          'sha': _branch,
          'per_page': 1,
        },
      );

      final commits = response.data ?? [];

      if (commits.isEmpty) {
        throw Exception(
          'No commits found for $path',
        );
      }

      final firstCommit = commits.first;

      if (firstCommit is! Map<String, dynamic>) {
        throw Exception(
          'Invalid GitHub commit response for $path',
        );
      }

      final sha = firstCommit['sha'] as String?;

      if (sha == null || sha.isEmpty) {
        throw Exception(
          'GitHub returned an empty SHA for $path',
        );
      }

      debugPrint(
        '[GITHUB] Latest commit for $path: $sha',
      );

      return sha;
    }

    // =========================================================================
    // PUBLIC WRITE API
    // =========================================================================

    // -------------------------------------------------------------------------
    // CREATE BRANCH
    // -------------------------------------------------------------------------

    Future<String> createBranch(
      String baseBranch,
      String newBranchName,
    ) async {
      debugPrint(
        '[GITHUB] Creating branch: '
        '$newBranchName from $baseBranch',
      );

      try {
        final refResponse =
            await _api.get<Map<String, dynamic>>(
          '/repos/$_owner/$_repo/git/ref/heads/$baseBranch',
        );

        final refData = refResponse.data;

        if (refData == null) {
          throw Exception(
            'Empty GitHub ref response.',
          );
        }

        final object =
            refData['object'] as Map<String, dynamic>?;

        final sha = object?['sha'] as String?;

        if (sha == null || sha.isEmpty) {
          throw Exception(
            'Could not determine SHA for branch $baseBranch',
          );
        }

        final response =
            await _api.post<Map<String, dynamic>>(
          '/repos/$_owner/$_repo/git/refs',
          data: {
            'ref': 'refs/heads/$newBranchName',
            'sha': sha,
          },
        );

        final responseData = response.data;

        final responseObject =
            responseData?['object']
                as Map<String, dynamic>?;

        final newSha =
            responseObject?['sha'] as String?;

        if (newSha == null || newSha.isEmpty) {
          throw Exception(
            'GitHub did not return the new branch SHA.',
          );
        }

        debugPrint(
          '[GITHUB] Branch created: '
          '$newBranchName ($newSha)',
        );

        return newSha;
      } on DioException catch (e) {
        debugPrint(
          '[ERROR][GITHUB] Branch creation failed',
        );

        debugPrint(
          '[ERROR][GITHUB] Status: '
          '${e.response?.statusCode}',
        );

        debugPrint(
          '[ERROR][GITHUB] Reason: ${e.message}',
        );

        rethrow;
      }
    }

    // -------------------------------------------------------------------------
    // CREATE OR UPDATE FILE
    // -------------------------------------------------------------------------

    Future<void> createOrUpdateFile(
      String branch,
      String path,
      String content,
      String commitMessage,
    ) async {
      debugPrint(
        '[GITHUB] Writing file: $path',
      );

      String? existingSha;

      try {
        final existing =
            await _api.get<Map<String, dynamic>>(
          '/repos/$_owner/$_repo/contents/$path',
          queryParameters: {
            'ref': branch,
          },
        );

        existingSha =
            existing.data?['sha'] as String?;
      } on DioException catch (e) {
        final statusCode =
            e.response?.statusCode;

        if (statusCode != 404) {
          debugPrint(
            '[ERROR][GITHUB] '
            'Failed to check existing file.',
          );

          rethrow;
        }

        // 404 means the file does not exist.
        existingSha = null;
      }

      final encodedContent =
          base64Encode(
        utf8.encode(content),
      );

      final data = <String, dynamic>{
        'message': commitMessage,
        'content': encodedContent,
        'branch': branch,
        if (existingSha != null)
          'sha': existingSha,
      };

      await _api.put(
        '/repos/$_owner/$_repo/contents/$path',
        data: data,
      );

      debugPrint(
        '[GITHUB] File committed successfully: $path',
      );
    }

    // -------------------------------------------------------------------------
    // CREATE PULL REQUEST
    // -------------------------------------------------------------------------

    Future<String> createPullRequest(
      String headBranch,
      String baseBranch,
      String title,
      String body,
    ) async {
      debugPrint(
        '[GITHUB] Creating PR: '
        '$headBranch → $baseBranch',
      );

      final response =
          await _api.post<Map<String, dynamic>>(
        '/repos/$_owner/$_repo/pulls',
        data: {
          'title': title,
          'body': body,
          'head': headBranch,
          'base': baseBranch,
        },
      );

      final htmlUrl =
          response.data?['html_url'] as String?;

      if (htmlUrl == null || htmlUrl.isEmpty) {
        throw Exception(
          'GitHub did not return the Pull Request URL.',
        );
      }

      debugPrint(
        '[GITHUB] Pull Request created: $htmlUrl',
      );

      return htmlUrl;
    }

    // -------------------------------------------------------------------------
    // MERGE PULL REQUEST
    // -------------------------------------------------------------------------

    Future<bool> mergePullRequest(
      int pullNumber,
    ) async {
      debugPrint(
        '[GITHUB] Merging PR #$pullNumber',
      );

      try {
        final response = await _api.put<
            Map<String, dynamic>>(
          '/repos/$_owner/$_repo/pulls/$pullNumber/merge',
          data: {
            'merge_method': 'merge',
          },
        );

        final merged =
            response.data?['merged'];

        if (merged is bool) {
          debugPrint(
            '[GITHUB] PR #$pullNumber merged: $merged',
          );

          return merged;
        }

        debugPrint(
          '[GITHUB] PR #$pullNumber merge request completed',
        );

        return true;
      } on DioException catch (e) {
        debugPrint(
          '[ERROR][GITHUB] Merge failed',
        );

        debugPrint(
          '[ERROR][GITHUB] Status: '
          '${e.response?.statusCode}',
        );

        debugPrint(
          '[ERROR][GITHUB] Reason: ${e.message}',
        );

        rethrow;
      }
    }

    // -------------------------------------------------------------------------
    // CLOSE PULL REQUEST
    // -------------------------------------------------------------------------

    Future<void> closePullRequest(
      int pullNumber,
    ) async {
      debugPrint(
        '[GITHUB] Closing PR #$pullNumber',
      );

      try {
        await _api.patch(
          '/repos/$_owner/$_repo/pulls/$pullNumber',
          data: {
            'state': 'closed',
          },
        );

        debugPrint(
          '[GITHUB] PR #$pullNumber closed',
        );
      } on DioException catch (e) {
        debugPrint(
          '[ERROR][GITHUB] '
          'Failed to close PR #$pullNumber',
        );

        debugPrint(
          '[ERROR][GITHUB] Status: '
          '${e.response?.statusCode}',
        );

        debugPrint(
          '[ERROR][GITHUB] Reason: ${e.message}',
        );

        rethrow;
      }
    }

    // =========================================================================
    // PRIVATE GITHUB HELPERS
    // =========================================================================

    /// Gets the current HEAD commit SHA of main.
    ///
    /// THIS IS THE IMPORTANT PART OF THE NEW IMPLEMENTATION.
    ///
    /// We do NOT ask jsDelivr to resolve:
    ///
    ///     @main
    ///
    /// We first resolve:
    ///
    ///     main -> abc123...
    ///
    /// and then use:
    ///
    ///     @abc123...
    ///
    /// with jsDelivr.
    Future<String> _getLatestMainSha() async {
      debugPrint(
        '[GITHUB] Checking latest $_branch commit...',
      );

      final response =
          await _getWithRetry<Map<String, dynamic>>(
        '/repos/$_owner/$_repo/commits/$_branch',
      );

      final data = response.data;

      if (data == null) {
        throw Exception(
          'Empty GitHub commit response.',
        );
      }

      final sha = data['sha'] as String?;

      if (sha == null || sha.isEmpty) {
        throw Exception(
          'GitHub returned an invalid main commit SHA.',
        );
      }

      debugPrint(
        '[GITHUB] Latest $_branch SHA: $sha',
      );

      return sha;
    }

    // =========================================================================
    // RAW CONTENT
    // =========================================================================

    /// Fetches a file from jsDelivr using an exact Git commit SHA.
    Future<String> _getRaw(
      String path,
    ) async {
      if (path.trim().isEmpty) {
        throw ArgumentError(
          'GitHub path cannot be empty.',
        );
      }

      final sha = await _getLatestMainSha();

      final cleanPath = path.startsWith('/')
          ? path.substring(1)
          : path;

      final url =
          'https://cdn.jsdelivr.net/gh/'
          '$_owner/$_repo@$sha/$cleanPath';

      debugPrint(
        '[GITHUB][CDN] Fetching immutable URL:',
      );

      debugPrint(
        '[GITHUB][CDN] $url',
      );

      final dio = Dio(
        BaseOptions(
          responseType: ResponseType.plain,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 20),
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );

      try {
        final response =
            await _cdnWithRetry(
          dio,
          url,
        );

        return response.data?.toString() ?? '';
      } finally {
        dio.close(force: true);
      }
    }

    // =========================================================================
    // CDN REQUEST WITH RETRY
    // =========================================================================

    Future<Response<String>> _cdnWithRetry(
      Dio dio,
      String url,
    ) async {
      const maxRetries = 2;

      var attempt = 0;

      while (true) {
        attempt++;

        debugPrint(
          '[GITHUB][CDN] GET attempt $attempt',
        );

        try {
          final response =
              await dio.get<String>(url);

          debugPrint(
            '[GITHUB][CDN] Request succeeded',
          );

          debugPrint(
            '[GITHUB][CDN] Status: '
            '${response.statusCode}',
          );

          return response;
        } on DioException catch (e) {
          final shouldRetry =
              _shouldRetry(e) &&
              attempt <= maxRetries;

          debugPrint(
            '[GITHUB][CDN] Request failed.',
          );

          debugPrint(
            '[GITHUB][CDN] Status: '
            '${e.response?.statusCode}',
          );

          debugPrint(
            '[GITHUB][CDN] Reason: '
            '${e.message ?? e.type.name}',
          );

          if (shouldRetry) {
            debugPrint(
              '[GITHUB][CDN] Retrying...',
            );

            await Future<void>.delayed(
              const Duration(seconds: 1),
            );

            continue;
          }

          rethrow;
        }
      }
    }

    // =========================================================================
    // GITHUB API REQUEST WITH RETRY
    // =========================================================================

    Future<Response<T>> _getWithRetry<T>(
      String path, {
      Map<String, dynamic>? queryParameters,
    }) async {
      debugPrint(
        '[GITHUB] GET $path',
      );

      const maxRetries = 2;

      var attempt = 0;

      while (true) {
        attempt++;

        debugPrint(
          '[GITHUB] Attempt $attempt',
        );

        try {
          final response =
              await _api.get<T>(
            path,
            queryParameters: queryParameters,
          );

          debugPrint(
            '[GITHUB] Request succeeded',
          );

          debugPrint(
            '[GITHUB] Status: '
            '${response.statusCode}',
          );

          return response;
        } on DioException catch (e) {
          final shouldRetry =
              _shouldRetry(e) &&
              attempt <= maxRetries;

          debugPrint(
            '[GITHUB] Request failed.',
          );

          debugPrint(
            '[GITHUB] Status: '
            '${e.response?.statusCode}',
          );

          debugPrint(
            '[GITHUB] Reason: '
            '${e.message ?? e.type.name}',
          );

          if (shouldRetry) {
            debugPrint(
              '[GITHUB] Retrying...',
            );

            await Future<void>.delayed(
              const Duration(seconds: 1),
            );

            continue;
          }

          rethrow;
        } catch (e) {
          debugPrint(
            '[ERROR][GITHUB] Unexpected error',
          );

          debugPrint(
            '[ERROR][GITHUB] Path: $path',
          );

          debugPrint(
            '[ERROR][GITHUB] Reason: $e',
          );

          rethrow;
        }
      }
    }

    // =========================================================================
    // RETRY POLICY
    // =========================================================================

    bool _shouldRetry(
      DioException error,
    ) {
      final statusCode =
          error.response?.statusCode;

      // Temporary server-side errors.
      if (statusCode != null &&
          statusCode >= 500) {
        return true;
      }

      // Rate limiting.
      if (statusCode == 429) {
        return true;
      }

      // Request timeout.
      if (statusCode == 408) {
        return true;
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return true;

        default:
          return false;
      }
    }
  }