import 'package:flutter/material.dart';

/// A reusable Google Sign-In button.
///
/// This widget does **not** call any service, repository, or Supabase directly.
/// It only accepts an `onPressed` callback and displays a styled button.
///
/// To use a custom Google icon, replace the `Icon(Icons.g_mobiledata)` with
/// an `Image.asset('assets/google_logo.png')` when the project provides one.
class GoogleSignInButton extends StatelessWidget {
  /// Called when the user taps the button.
  final VoidCallback? onPressed;

  /// Whether the button is in a loading state.
  final bool isLoading;

  /// Whether the button is enabled.
  final bool isEnabled;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = isLoading || !isEnabled;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: disabled ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: const BorderSide(color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replace with Image.asset('assets/google_logo.png') when available
                  Icon(Icons.g_mobiledata, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }
}