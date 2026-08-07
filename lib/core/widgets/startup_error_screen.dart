import 'package:flutter/material.dart';

/// A minimal error screen shown when a critical startup step (e.g. Supabase,
/// dependency injection) fails.
///
/// Displays a user‑safe [message] and an optional retry button. Technical
/// details must **never** be passed to this widget – they should have been
/// logged by the startup layer.
class StartupErrorScreen extends StatelessWidget {
  /// Human-readable description of the problem.
  final String message;

  /// Called when the user taps “Retry”. If `null`, no button is shown.
  final VoidCallback? onRetry;

  /// Called when the user taps “Exit”. If `null`, no exit button is shown.
  final VoidCallback? onExit;

  const StartupErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Startup Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                if (onExit != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onExit,
                    icon: const Icon(Icons.close),
                    label: const Text('Exit'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}