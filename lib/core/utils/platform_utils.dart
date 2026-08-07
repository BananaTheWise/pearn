import 'package:flutter/foundation.dart';

/// Centralised platform checks.
///
/// Admin and tutor tooling is desktop-only by design — those workflows
/// involve dense tables, multi-panel review screens, and course editing
/// that aren't meant for a phone screen. This is a platform restriction,
/// independent of the signed-in user's role.
class PlatformUtils {
  /// True on Android or iOS (native mobile builds).
  ///
  /// Web is intentionally treated as non-mobile here, since a Chromebook
  /// or desktop browser session shouldn't be blocked just because Flutter
  /// web reports a generic platform. If you later want to also block
  /// mobile *browsers*, this is the place to add that check.
  static bool get isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isDesktop => !isMobile;
}