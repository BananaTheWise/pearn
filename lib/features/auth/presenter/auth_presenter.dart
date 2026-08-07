import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/session.dart';
import '../../../core/models/user.dart';
import '../../auth/model/auth_service.dart';
import '../../auth/view/i_auth_view.dart';

/// Coordinates between the authentication UI ([IAuthView]) and the backend
/// ([AuthService]).
///
/// The presenter never performs database queries or direct Supabase calls.
class AuthPresenter {
  final AuthService _authService;
  IAuthView? _view;
  StreamSubscription<AuthState>? _authStateSub;

  AuthPresenter({required AuthService authRepo}) : _authService = authRepo;

  /// Attaches the view that will receive UI updates.
  set view(IAuthView? view) {
    _view = view;
    if (view != null) {
      _startListeningToAuthState();
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Sign Up
  // ---------------------------------------------------------------------------
  Future<void> signUp(String email, String password) async {
    debugPrint('[PRESENTER][AUTH] Signup started');
    _view?.showLoading(true);

    try {
      final user = await _authService.signUp(email, password);
      debugPrint('[PRESENTER][AUTH] Signup succeeded');

      // The architecture may show a verification prompt.
      _view?.showVerificationPrompt();
    } catch (e) {
      debugPrint('[PRESENTER][AUTH] Signup failed');
      _view?.showValidationError(_mapErrorToMessage(e));
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. Login
  // ---------------------------------------------------------------------------
  Future<void> login(String email, String password) async {
    debugPrint('[PRESENTER][AUTH] Login started');
    _view?.showLoading(true);

    try {
      final session = await _authService.login(email, password);
      debugPrint('[PRESENTER][AUTH] Login succeeded');
      _view?.navigateToHome();
    } catch (e) {
      debugPrint('[PRESENTER][AUTH] Login failed');
      _view?.showValidationError(_mapErrorToMessage(e));
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Google Sign-In
  // ---------------------------------------------------------------------------
  Future<void> signInWithGoogle() async {
    debugPrint('[PRESENTER][AUTH][GOOGLE] Sign-in started');
    _view?.showLoading(true);

    try {
      final user = await _authService.signInWithGoogle();
      debugPrint('[PRESENTER][AUTH][GOOGLE] Sign-in succeeded');
      _view?.navigateToHome();
    } on GoogleSignInCancelledException {
      debugPrint('[PRESENTER][AUTH][GOOGLE] Sign-in cancelled');
      // Do not show an error – the user cancelled on purpose.
    } catch (e) {
      debugPrint('[PRESENTER][AUTH][GOOGLE] Sign-in failed');
      _view?.showValidationError(_mapErrorToMessage(e));
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Logout
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Ignore logout errors – the session will be cleared anyway.
    }
    // Navigate to login even if the backend call fails.
    _view?.showLoginForm();
  }

  // ---------------------------------------------------------------------------
  // 5. Request Password Reset
  // ---------------------------------------------------------------------------
  Future<void> requestPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      _view?.showValidationError('Please enter your email address.');
      return;
    }

    _view?.showLoading(true);
    try {
      await _authService.requestPasswordReset(email);
      _view?.showValidationError('Password reset email sent. Check your inbox.');
    } catch (e) {
      debugPrint('[PRESENTER][AUTH] Password reset request failed');
      _view?.showValidationError('Failed to send reset email. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 6. Reset Password (after deep link)
  // ---------------------------------------------------------------------------
  Future<void> resetPassword(String newPassword) async {
    // Basic validation
    if (newPassword.isEmpty || newPassword.length < 6) {
      _view?.showValidationError('Password must be at least 6 characters.');
      return;
    }

    _view?.showLoading(true);
    try {
      await _authService.resetPassword(newPassword);
      _view?.showValidationError('Password updated successfully.');
      _view?.showLoginForm();
    } catch (e) {
      debugPrint('[PRESENTER][AUTH] Password reset failed');
      _view?.showValidationError('Could not reset password. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------
  void dispose() {
    _authStateSub?.cancel();
    _view = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Converts technical exceptions into user-safe messages.
  String _mapErrorToMessage(Object e) {
    // Map known Supabase errors / common failure codes.
    final message = e.toString().toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Invalid email or password.';
    }
    if (message.contains('email not confirmed') ||
        message.contains('email not verified')) {
      return 'Please verify your email address first.';
    }
    if (message.contains('user already registered') ||
        message.contains('duplicate')) {
      return 'An account with this email already exists.';
    }
    // Generic fallback
    return 'An unexpected error occurred. Please try again later.';
  }

  /// Listens to auth state changes to react to external events (e.g. token expiry).
  void _startListeningToAuthState() {
    _authStateSub?.cancel();
    _authStateSub = _authService.authStateChanges().listen((state) {
      if (state == AuthState.unauthenticated) {
        // Session ended externally (e.g. token revoked).
        debugPrint('[PRESENTER][AUTH] Auth state changed to unauthenticated');
        _view?.showLoginForm();
      }
    });
  }
}