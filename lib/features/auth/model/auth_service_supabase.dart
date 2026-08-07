import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_flutter;

import '../../../core/models/session.dart';
import '../../../core/models/user.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/model/auth_service.dart';
import '../../auth/model/user_repository.dart';

/// Exception thrown when the user cancels the Google Sign-In flow.
class GoogleSignInCancelledException implements Exception {}

/// Concrete implementation of [AuthService] using Supabase and Google Sign-In.
class AuthServiceSupabase implements AuthService {
  final SupabaseService _supabaseService;
  final GoogleAuthService _googleAuthService;
  final UserRepository _userRepository;

  /// Broadcast stream that emits the current [AuthState] whenever it changes.
  late final Stream<AuthState> _authStateStream;

  AuthServiceSupabase({
    required this._supabaseService,
    required this._googleAuthService,
    required this._userRepository,
  }) {
    _authStateStream = _buildAuthStateStream().asBroadcastStream();
  }

  // ---------------------------------------------------------------------------
  // 1. signUp
  // ---------------------------------------------------------------------------
  @override
  Future<User> signUp(String email, String password) async {
    debugPrint('[AUTH] Signup started');

    try {
      debugPrint('[AUTH] Calling Supabase signup');
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      final supabaseUser = response.user;
      if (supabaseUser == null) {
        throw Exception('Supabase signup did not return a user');
      }

      debugPrint('[AUTH] Supabase signup succeeded');

      // Profile row is created automatically by the on_auth_user_created
      // trigger — no client-side insert needed (and none would work
      // reliably here anyway, since there may be no session yet if email
      // confirmation is required).
      if (response.session != null) {
        // We have a session — fetch the profile the trigger just created.
        final savedUser = await _userRepository.findById(supabaseUser.id);
        if (savedUser != null) {
          debugPrint('[AUTH] Signup completed');
          return savedUser;
        }
      }

      // No session yet (email confirmation pending) — return a local
      // placeholder; the real profile will be fetched on first login.
      debugPrint('[AUTH] Signup completed, awaiting email confirmation');
      return User(
        id: supabaseUser.id,
        username: email.split('@').first,
        role: User.roleStudent,
        status: User.statusActive,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[ERROR][AUTH] Signup failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. login
  // ---------------------------------------------------------------------------
  @override
  Future<Session> login(String email, String password) async {
    debugPrint('[AUTH] Login started');
    debugPrint('[AUTH] Authenticating with Supabase');

    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('[AUTH] Login successful');
      return _mapSession(response.session);
    } catch (e) {
      debugPrint('[ERROR][AUTH] Login failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. signInWithGoogle
  // ---------------------------------------------------------------------------
  @override
  Future<User> signInWithGoogle() async {
    debugPrint('[AUTH][GOOGLE] Google sign-in started');

    try {
      final tokens = await _googleAuthService.signIn();

      if (tokens == null) {
        debugPrint('[AUTH][GOOGLE] User cancelled sign-in');
        throw GoogleSignInCancelledException();
      }

      debugPrint('[AUTH][GOOGLE] Google authentication completed');

      // Sign in to Supabase with Google credentials
      final response = await _supabaseService.client.auth.signInWithIdToken(
        provider: supabase_flutter.OAuthProvider.google,
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );

      debugPrint('[AUTH][GOOGLE] Supabase authentication completed');

      final supabaseUser = response.user;
      if (supabaseUser == null) {
        throw Exception('Supabase sign-in did not return a user');
      }

      // Check if a profile already exists
      debugPrint('[AUTH][GOOGLE] Checking profile');
      User? existingUser = await _userRepository.findById(supabaseUser.id);

      if (existingUser != null) {
        debugPrint('[AUTH][GOOGLE] Profile loaded');
        return existingUser;
      }

      // First login – create a new profile
      final newUser = User(
        id: supabaseUser.id,
        username: supabaseUser.email?.split('@').first ?? 'google_user',
        role: User.roleStudent,
        status: User.statusActive,
        createdAt: DateTime.now(),
      );

      final savedUser = await _userRepository.save(newUser);
      debugPrint('[AUTH][GOOGLE] Profile created');
      debugPrint('[AUTH][GOOGLE] Google sign-in completed');
      return savedUser;
    } on GoogleSignInCancelledException {
      rethrow;
    } catch (e) {
      debugPrint('[ERROR][AUTH][GOOGLE] Google sign-in failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 4. logout
  // ---------------------------------------------------------------------------
  @override
  Future<void> logout() async {
    debugPrint('[AUTH] Logout started');

    // Supabase sign out
    try {
      await _supabaseService.client.auth.signOut();
      debugPrint('[AUTH] Supabase session terminated');
    } catch (e) {
      debugPrint('[ERROR][AUTH] Failed to sign out from Supabase');
      // continue to clear Google session anyway
    }

    // Google session clear
    try {
      await _googleAuthService.signOut();
      debugPrint('[AUTH][GOOGLE] Google session cleared');
    } catch (e) {
      debugPrint('[ERROR][AUTH] Failed to clear Google session');
    }

    debugPrint('[AUTH] Logout completed');
  }

  // ---------------------------------------------------------------------------
  // 5. requestPasswordReset
  // ---------------------------------------------------------------------------
  @override
  Future<void> requestPasswordReset(String email) async {
    debugPrint('[AUTH] Password reset requested');

    try {
      await _supabaseService.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('[ERROR][AUTH] Password reset request failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 6. resetPassword
  // ---------------------------------------------------------------------------
  @override
  Future<void> resetPassword(String newPassword) async {
    debugPrint('[AUTH] Password reset update started');

    try {
      await _supabaseService.client.auth.updateUser(
        supabase_flutter.UserAttributes(password: newPassword),
      );
      debugPrint('[AUTH] Password reset completed');
    } catch (e) {
      debugPrint('[ERROR][AUTH] Password reset failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 7. authStateChanges
  // ---------------------------------------------------------------------------
  @override
  Stream<AuthState> authStateChanges() => _authStateStream;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Creates a [Session] from a Supabase session.
  Session _mapSession(supabase_flutter.Session? session) {
    if (session == null) {
      throw Exception('Session is null after login');
    }
    return Session(
      id: session.accessToken, // use access token as id if no separate id
      userId: session.user.id,
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (session.expiresAt ?? 0) * 1000,
      ),
    );
  }

  /// Builds the auth state change stream that emits the initial state and
  /// subsequent changes.
  Stream<AuthState> _buildAuthStateStream() async* {
    // Emit the current auth state
    yield _currentAuthState();
    debugPrint('[AUTH] Listening for auth state changes');

    await for (final event in _supabaseService.client.auth.onAuthStateChange) {
      final state = _mapSessionToState(event.session);
      debugPrint('[AUTH] Auth state changed: ${state.name}');
      yield state;
    }
  }

  AuthState _currentAuthState() {
    return _mapSessionToState(_supabaseService.client.auth.currentSession);
  }

  AuthState _mapSessionToState(supabase_flutter.Session? session) {
    return session != null
        ? AuthState.authenticated
        : AuthState.unauthenticated;
  }
}
