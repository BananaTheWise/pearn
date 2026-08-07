import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/theme_service.dart';
import '../../auth/model/auth_service.dart';
import '../view/i_settings_view.dart';

class SettingsPresenter {
  final AuthService _authService;
  final ThemeService _themeService;

  ISettingsView? _view;

  SettingsPresenter({
    required AuthService authService,
    required ThemeService themeService,
  })  : _authService = authService,
        _themeService = themeService;

  set view(ISettingsView? view) {
    _view = view;
  }

  /// Initialise the view with the current theme mode.
  void loadSettings() {
    _view?.updateThemeMode(_themeService.value);
  }

  /// Toggles the application theme.
  void setThemeMode(ThemeMode mode) {
    debugPrint('[UI][SETTINGS] Setting changed: theme = $mode');
    _themeService.value = mode;
    _view?.updateThemeMode(mode);
  }

  /// Logs the user out and navigates to login.
  Future<void> logout() async {
    _view?.showLoading(true);
    try {
      await _authService.logout();
      _view?.navigateToLogin();
    } catch (e) {
      debugPrint('[PRESENTER][SETTINGS] Logout failed');
      _view?.showError('Logout failed. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }
}