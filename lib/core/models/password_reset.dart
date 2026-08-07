/// Pure data model representing a password reset request.
///
/// This class holds the token and metadata required to reset a password.
/// It does **not** store or log the user's raw password – the new password
/// is never retained in this model.
///
/// All network and backend operations are performed by [AuthService], not
/// by this model.
class PasswordReset {
  /// The email address associated with the reset request.
  final String email;

  /// The secure reset token sent to the user.
  /// **Must not be printed in logs or debug output.**
  final String token;

  /// Timestamp when the reset request was created.
  final DateTime createdAt;

  /// Timestamp after which the token is no longer valid.
  final DateTime expiresAt;

  /// Whether the reset token has already been consumed.
  final bool isUsed;

  const PasswordReset({
    required this.email,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Returns `true` if the token has expired or has been used.
  bool get isValid => !isExpired && !isUsed;

  /// Returns `true` if the token has passed its expiration time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory PasswordReset.fromMap(Map<String, dynamic> map) {
    return PasswordReset(
      email: map['email'] as String,
      token: map['token'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isUsed: map['is_used'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'token': token,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
    };
  }

  // ---------------------------------------------------------------------------
  // Safety override – never expose the token
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'PasswordReset(email: $email, isUsed: $isUsed, '
        'createdAt: $createdAt, expiresAt: $expiresAt, isValid: $isValid)';
  }
}