import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInTokens {
  final String idToken;
  final String accessToken;

  const GoogleSignInTokens({
    required this.idToken,
    required this.accessToken,
  });
}

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _initialized = false;

  /// Initialize Google Sign-In.
  ///
  /// Replace the value below with your OAuth Desktop Client ID.
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('[AUTH][GOOGLE] Initializing Google Sign-In');

    await _googleSignIn.initialize(
      clientId: 'YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com',
    );

    _initialized = true;

    debugPrint('[AUTH][GOOGLE] Google Sign-In initialized');
  }

  /// Sign in with Google.
  Future<GoogleSignInTokens?> signIn() async {
    debugPrint('[AUTH][GOOGLE] Starting Google Sign-In');

    await initialize();

    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint(
          '[ERROR][AUTH][GOOGLE] '
          'This platform does not support authenticate().',
        );
        return null;
      }

      final account = await _googleSignIn.authenticate();

      debugPrint('[AUTH][GOOGLE] Google account authenticated');

      final authentication = account.authentication;

      return GoogleSignInTokens(
        idToken: authentication.idToken ?? '',
        accessToken: '',
      );
    } on GoogleSignInException catch (e) {
      debugPrint(
        '[ERROR][AUTH][GOOGLE] '
        'Google Sign-In failed: ${e.code}',
      );

      rethrow;
    } catch (e) {
      debugPrint('[ERROR][AUTH][GOOGLE] Google Sign-In failed');
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('[AUTH][GOOGLE] Signing out');

    try {
      await _googleSignIn.signOut();

      debugPrint('[AUTH][GOOGLE] Google session cleared');
    } catch (e) {
      debugPrint('[ERROR][AUTH][GOOGLE] Failed to sign out');
      rethrow;
    }
  }
} 