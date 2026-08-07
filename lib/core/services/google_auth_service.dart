import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Data class that holds the tokens returned by Google Sign-In.
class GoogleSignInTokens {
  final String idToken;
  final String accessToken;

  const GoogleSignInTokens({
    required this.idToken,
    required this.accessToken,
  });
}

/// Wraps native Google Sign-In functionality.
///
/// This is the **only** file in the application allowed to import and use
/// the `google_sign_in` package directly.
class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              // Request email scope so the account picker can show a user-friendly label.
              scopes: ['email'],
            );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Opens the native Google account picker and returns the authentication tokens.
  ///
  /// Returns `null` if the user cancels the sign-in flow.
  Future<GoogleSignInTokens?> signIn() async {
    debugPrint('[AUTH][GOOGLE] Starting Google Sign-In');
    debugPrint('[AUTH][GOOGLE] Opening account picker');

    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        debugPrint('[AUTH][GOOGLE] User cancelled Google Sign-In');
        return null;
      }

      debugPrint('[AUTH][GOOGLE] Google account selected');

      final authentication = await account.authentication;

      debugPrint('[AUTH][GOOGLE] Google authentication tokens obtained');

      return GoogleSignInTokens(
        idToken: authentication.idToken ?? '',
        accessToken: authentication.accessToken ?? '',
      );
    } catch (e) {
      // Log a safe error message – no tokens are ever included.
      debugPrint('[ERROR][AUTH][GOOGLE] Google Sign-In failed');
      // Rethrow for the caller to handle (e.g. show an error UI).
      rethrow;
    }
  }

  /// Signs the user out and clears the local Google session.
  Future<void> signOut() async {
    debugPrint('[AUTH][GOOGLE] Signing out');
    try {
      await _googleSignIn.signOut();
      debugPrint('[AUTH][GOOGLE] Google session cleared');
    } catch (e) {
      debugPrint('[ERROR][AUTH][GOOGLE] Failed to clear Google session');
      rethrow;
    }
  }
}