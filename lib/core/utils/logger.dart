import 'package:flutter/foundation.dart';

/// Centralised application logging utility.
///
/// Provides structured log messages in the format:
/// `[LEVEL][MODULE][COMPONENT] message`
///
/// Automatically filters out potential secrets from log messages.
/// Verbose debug logs can be suppressed in production builds.
class Logger {
  // ---------------------------------------------------------------------------
  // Singleton (optional)
  // ---------------------------------------------------------------------------
  Logger._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Debug-level log.  Suppressed in release mode unless [force] is true.
  static void debug(String module, String component, String message) {
    _log('DEBUG', module, component, message);
  }

  /// Informational log.
  static void info(String module, String component, String message) {
    _log('INFO', module, component, message);
  }

  /// Warning log.
  static void warning(String module, String component, String message) {
    _log('WARNING', module, component, message);
  }

  /// Error log.
  static void error(String module, String component, String message) {
    _log('ERROR', module, component, message);
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------
  static void _log(String level, String module, String component, String message) {
    // Suppress debug logs in release mode
    if (level == 'DEBUG' && kReleaseMode) return;

    final filteredMessage = _filterSecrets(message);
    final fullMessage = '[$level][$module][$component] $filteredMessage';

    // Use debugPrint which is safe for Flutter and can be redirected.
    debugPrint(fullMessage);
  }

  // List of keys that should be considered sensitive.
  // If a key appears in a log message, its value is replaced with `[REDACTED]`.
  static final List<String> _sensitiveKeys = [
    'password',
    'access_token',
    'refresh_token',
    'apikey',
    'api_key',
    'token',
    'secret',
    'authorization',
    'supabase_key',
    'github_token',
    'supabase_anon_key',
  ];

  /// Very basic secret redaction.
  /// If the message contains a known sensitive key followed by a colon or equals,
  /// the value is replaced with `[REDACTED]`.
  static String _filterSecrets(String message) {
    String filtered = message;
    for (final key in _sensitiveKeys) {
      // Match patterns like "key = value" or "key: value" or "key=value" etc.
      final regex = RegExp(
        '($key)\\s*[:=]\\s*\\S+',
        caseSensitive: false,
      );
      filtered = filtered.replaceAllMapped(regex, (match) {
        final prefix = match.group(1)!;
        return '$prefix = [REDACTED]';
      });
    }
    return filtered;
  }
}