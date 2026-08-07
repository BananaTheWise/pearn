import 'package:flutter/material.dart';

/// Minimal theme management service.
///
/// Registered as a singleton in DI so the entire app can react to theme changes.
class ThemeService extends ValueNotifier<ThemeMode> {
  ThemeService() : super(ThemeMode.system);
}