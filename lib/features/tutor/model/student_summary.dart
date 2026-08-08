/// Minimal student identity for list display purposes (tutor dashboard's
/// student list). Distinct from [StudentStat], which carries full
/// per-course statistics.
class StudentSummary {
  /// profiles.id
  final String id;

  /// profiles.username
  final String username;

  const StudentSummary({
    required this.id,
    required this.username,
  });

  factory StudentSummary.fromMap(Map<String, dynamic> map) {
    return StudentSummary(
      id: map['id'] as String,
      username: map['username'] as String? ?? map['id'] as String,
    );
  }
}