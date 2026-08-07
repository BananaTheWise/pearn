/// Pure data model representing the state of an email verification process.
///
/// This class does not depend on Flutter, Supabase, or any service/repository.
/// It is a plain Dart object that holds the data required to track email
/// verification, regardless of whether a dedicated database table exists.
///
/// **Important:** The `token` field is never printed in logs or debug output.
class EmailVerification {
  /// The email address being verified.
  final String email;

  /// The verification token sent to the user.
  /// This value is sensitive and must **not** appear in logs.
  final String token;

  /// Whether the email has been successfully verified.
  final bool isVerified;

  /// Timestamp when the verification record was created.
  final DateTime createdAt;

  /// Timestamp when the verification token expires.
  final DateTime expiresAt;

  const EmailVerification({
    required this.email,
    required this.token,
    this.isVerified = false,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Creates an [EmailVerification] from a map (e.g. from a local cache or
  /// a hypothetical database row).
  factory EmailVerification.fromMap(Map<String, dynamic> map) {
    return EmailVerification(
      email: map['email'] as String,
      token: map['token'] as String,
      isVerified: map['is_verified'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  /// Converts this [EmailVerification] to a map.
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'token': token,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Returns `true` if the verification token has expired.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Override `toString` to exclude the sensitive token.
  @override
  String toString() {
    return 'EmailVerification(email: $email, isVerified: $isVerified, '
        'createdAt: $createdAt, expiresAt: $expiresAt)';
  }
}