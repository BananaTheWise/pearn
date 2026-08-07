/// Pure data model representing an application policy (e.g., Terms & Conditions).
///
/// Users and tutors may be required to accept certain policies before
/// accessing platform functionality. This model stores the policy content
/// and metadata; acceptance tracking is managed separately.
class Policy {
  /// Unique identifier for the policy (e.g., `'terms_of_service'`).
  final String id;

  /// Display title of the policy.
  final String title;

  /// Full policy text in Markdown or plain text.
  final String content;

  /// Semantic version string for the policy (e.g., `'1.0.0'`).
  final String version;

  /// Whether this policy must be accepted before using the application.
  final bool isRequired;

  /// Timestamp when the policy was created.
  final DateTime createdAt;

  /// Timestamp when the policy was last updated.
  final DateTime updatedAt;

  const Policy({
    required this.id,
    required this.title,
    required this.content,
    required this.version,
    this.isRequired = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory Policy.fromMap(Map<String, dynamic> map) {
    return Policy(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      version: map['version'] as String,
      isRequired: map['is_required'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'version': version,
      'is_required': isRequired,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & debug
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Policy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => id.hashCode ^ version.hashCode;

  @override
  String toString() =>
      'Policy(id: $id, title: $title, version: $version, '
      'isRequired: $isRequired, updatedAt: $updatedAt)';
}