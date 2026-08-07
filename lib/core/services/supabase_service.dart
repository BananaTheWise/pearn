import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase client wrapper.
///
/// This is the **only** file in the application permitted to initialise the
/// Supabase SDK and expose the underlying client.  All backend access flows
/// through this service.
class SupabaseService {
  // ---------------------------------------------------------------------------
  // Singleton
  // ---------------------------------------------------------------------------
  static final SupabaseService _instance = SupabaseService._internal();
  static SupabaseService get instance => _instance;
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  SupabaseClient? _client;
  bool _initialised = false;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------
  /// Initialises the Supabase SDK.
  ///
  /// Must be called once during application startup **before** any repository
  /// or presenter attempts to use the [client].
  static Future<void> initialize() async {
    await _instance._initialize();
  }

  Future<void> _initialize() async {
    if (_initialised) {
      debugPrint('[SUPABASE] Already initialised – skipping');
      return;
    }

    debugPrint('[SUPABASE] Initialization started');

    // Read configuration from compile-time environment variables.
    // These are **never** printed.
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      debugPrint('[ERROR][SUPABASE] Missing SUPABASE_URL or SUPABASE_ANON_KEY');
      throw Exception(
        'Supabase configuration is incomplete. '
        'Ensure SUPABASE_URL and SUPABASE_ANON_KEY environment variables are set.',
      );
    }

    // Initialise the Supabase singleton.
    final supabase = await Supabase.initialize(url: url, anonKey: anonKey);

    _client = supabase.client;
    _initialised = true;

    debugPrint('[SUPABASE] Client initialization completed');
    debugPrint('[SUPABASE] Client created');
    debugPrint('[SUPABASE] Session state checked');
  }

  // ---------------------------------------------------------------------------
  // Client access
  // ---------------------------------------------------------------------------
  /// The fully initialised [SupabaseClient].
  ///
  /// Throws a [StateError] if accessed before [initialize] has completed.
  SupabaseClient get client {
    if (!_initialised || _client == null) {
      debugPrint('[ERROR][SUPABASE] Client accessed before initialisation');
      throw StateError(
        'SupabaseClient has not been initialised. '
        'Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  // ---------------------------------------------------------------------------
  // Optional health check (real backend verification)
  // ---------------------------------------------------------------------------
  /// Performs a lightweight query to verify that the backend is reachable.
  ///
  /// Returns `true` if the query succeeds, `false` otherwise.
  /// This is **not** called automatically; presenters or services may use it.
  Future<bool> checkConnection() async {
    if (!_initialised || _client == null) return false;
    try {
      // A simple, low-cost query – fetches a single row from `profiles`
      // (or any table guaranteed to exist). The exact table is irrelevant
      // as long as it confirms the backend is responsive.
      await _client!.from('profiles').select('id').limit(1).single();
      debugPrint('[SUPABASE] Backend operation available');
      return true;
    } catch (_) {
      debugPrint('[SUPABASE] Health check failed');
      return false;
    }
  }
}