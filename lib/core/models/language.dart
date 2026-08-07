/// Pure data model representing a programming language or learning category.
///
/// This model does not depend on Flutter, Supabase, or any service/repository.
/// It is used to filter and categorize courses.
class Language {
  /// Unique identifier (e.g., `'python'`, `'javascript'`).
  final String id;

  /// Human-readable name (e.g., `'Python'`, `'JavaScript'`).
  final String name;

  const Language({required this.id, required this.name});

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // ---------------------------------------------------------------------------
  // Equality & debug
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Language(id: $id, name: $name)';
}