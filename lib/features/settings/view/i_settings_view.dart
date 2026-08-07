import 'package:flutter/material.dart';

abstract class ISettingsView {
  void showLoading(bool loading);
  void showError(String message);
  void showSuccess(String message);
  void navigateToLogin();
  void updateThemeMode(ThemeMode mode);
}