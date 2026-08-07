/// Pure representation of an authenticated application session.
///
/// This class holds session tokens and expiration information. It does **not**
/// perform any network calls, authentication, or backend communication.
///
/// Refreshing tokens and terminating a session are handled by [AuthService].
/// The methods [refresh] and [terminate] are present to satisfy the
/// architecture contract but are implemented as no‑ops – they do not modify
/// the underlying server-side state.
class Session {
  /// Unique identifier for the session (may be empty if not tracked).
  final String id;

  /// The ID of the authenticated user.
  final String userId;

  /// Short-lived access token.
  final String accessToken;

  /// Long-lived refresh token.
  final String refreshToken;

  /// Timestamp when the access token expires.
  final DateTime expiresAt;

  const Session({
    required this.id,
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` if the current access token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String,
      accessToken: map['access_token'] as String,
      refreshToken: map['refresh_token'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Contract methods (pure – no external calls)
  // ---------------------------------------------------------------------------

  /// Placeholder for session refresh.
  ///
  /// **Important:** This method does **not** perform a token refresh.
  /// Actual token refreshing is handled by [AuthService] and results in a new
  /// [Session] instance.
  Session refresh() {
    // Return the same session unchanged.
    // AuthService is responsible for obtaining fresh tokens and creating a
    // new Session object.
    return this;
  }

  /// Placeholder for session termination.
  ///
  /// **Important:** This method does **not** invalidate the session on the
  /// backend. Logout and session termination are performed by [AuthService].
  void terminate() {
    // No-op.
    // AuthService will clear stored tokens and call the Supabase sign out.
  }

  // ---------------------------------------------------------------------------
  // Helper
  // ---------------------------------------------------------------------------

  /// Creates a copy with the given fields replaced.
  Session copyWith({
    String? id,
    String? userId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() => 'Session(id: $id, userId: $userId, '
      'expiresAt: $expiresAt, isExpired: $isExpired)';
}