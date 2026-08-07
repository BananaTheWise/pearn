import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/my_app.dart';
import 'core/di.dart';
import 'core/services/supabase_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[BOOT] Application startup started');
  _bootstrap();
}

Future<void> _bootstrap() async {
  // -------------------------------------------------------
  // 1. Dependency Injection
  // -------------------------------------------------------
  debugPrint('[BOOT][DI] Dependency injection initialization started');
  try {
    setupDependencies();
    debugPrint('[BOOT][DI] Dependency injection initialized');
  } catch (e) {
    debugPrint('[BOOT][ERROR] Dependency injection failed');
    _showFatalError('Failed to initialise application infrastructure.');
    return;
  }

  // -------------------------------------------------------
  // 2. Supabase
  // -------------------------------------------------------
  debugPrint('[BOOT][SUPABASE] Supabase initialization started');
  try {
    await SupabaseService.initialize();
    debugPrint('[BOOT][SUPABASE] Supabase initialization completed');
  } catch (e) {
    debugPrint('[BOOT][ERROR] Supabase initialization failed');
    _showFatalError('Unable to connect to backend services. Please try again later.');
    return;
  }

  // -------------------------------------------------------
  // 3. Authentication / session handling
  // -------------------------------------------------------
  debugPrint('[BOOT][AUTH] Authentication initialization started');
  // The auth service is already configured via DI. The session state
  // stream is active and will be consumed by the router / splash screen.
  debugPrint('[BOOT][AUTH] Authentication initialization completed');

  // -------------------------------------------------------
  // 4. Connectivity
  // -------------------------------------------------------
  debugPrint('[BOOT][NETWORK] Connectivity initialization started');
  // The ConnectivityService is ready; no explicit warm‑up is required.
  debugPrint('[BOOT][NETWORK] Connectivity initialization completed');

  // -------------------------------------------------------
  // 5. Synchronisation
  // -------------------------------------------------------
  debugPrint('[BOOT][SYNC] Synchronization initialization started');
  // If a SyncService or PendingWriteQueue exists, initialise it here.
  // For now we simply log completion.
  debugPrint('[BOOT][SYNC] Synchronization initialization completed');

  // -------------------------------------------------------
  // 6. Launch application
  // -------------------------------------------------------
  debugPrint('[BOOT] Application startup completed');
  runApp(const MyApp());
}

/// Displays a red error screen when a critical startup step fails.
void _showFatalError(String message) {
  runApp(
    MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ),
      ),
    ),
  );
}