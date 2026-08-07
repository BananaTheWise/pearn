/// Pure data model representing a course category or classification.
///
/// Categories may originate from GitHub course metadata (e.g., `meta.json`)
/// rather than a Supabase table. This model is kept simple and compatible
/// with the GitHub course representation.
class Category {
  /// Unique identifier for the category (e.g., `'beginner'`, `'advanced'`).
  final String id;

  /// Human-readable name (e.g., `'Beginner'`, `'Advanced'`).
  final String name;

  const Category({required this.id, required this.name});

  // ---------------------------------------------------------------------------
  // Factory & serialization
  // ---------------------------------------------------------------------------

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
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
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name)';
}