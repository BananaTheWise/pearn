/// Pure data model representing a user's acceptance of a specific policy.
///
/// This model links a [User] to a [Policy] and records when the acceptance
/// occurred. Persistence and database operations are handled by repositories
/// – this class is purely a data container.
class PolicyAcceptance {
  /// The ID of the user who accepted the policy.
  final String userId;

  /// The ID of the accepted policy.
  final String policyId;

  /// Timestamp when the user accepted the policy.
  final DateTime acceptedAt;

  const PolicyAcceptance({
    required this.userId,
    required this.policyId,
    required this.acceptedAt,
  });

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory PolicyAcceptance.fromMap(Map<String, dynamic> map) {
    return PolicyAcceptance(
      userId: map['user_id'] as String,
      policyId: map['policy_id'] as String,
      acceptedAt: DateTime.parse(map['accepted_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'policy_id': policyId,
      'accepted_at': acceptedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & debug
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolicyAcceptance &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          policyId == other.policyId;

  @override
  int get hashCode => userId.hashCode ^ policyId.hashCode;

  @override
  String toString() =>
      'PolicyAcceptance(userId: $userId, policyId: $policyId, '
      'acceptedAt: $acceptedAt)';
}