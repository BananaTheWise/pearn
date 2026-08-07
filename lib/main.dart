import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di.dart';
import 'core/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[BOOT] Offline application startup started');

  try {
    debugPrint('[BOOT][DI] Initializing dependency injection');
    setupDependencies();
    debugPrint('[BOOT][DI] Dependency injection initialized');

    // Try to bring Supabase online, but don't crash the app if it fails
    // (no internet, bad config, etc.) — offline/local features must still work.
    try {
      debugPrint('[BOOT][SUPABASE] Initializing Supabase');
      await SupabaseService.initialize();
      debugPrint('[BOOT][SUPABASE] Supabase ready');
    } catch (e) {
      debugPrint('[BOOT][SUPABASE] Supabase unavailable, continuing offline: $e');
      // App proceeds without Supabase. Any screen needing it should check
      // SupabaseService.instance.isReady before calling .client.
    }

    debugPrint('[BOOT] Launching offline application');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('[BOOT][ERROR] Application startup failed');
    debugPrint('$e');
    debugPrint('$stackTrace');

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to start application.\n\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}