/// Identifies the course and lesson a note belongs to.
///
/// Notes are stored in Supabase using:
///   attached_to_type = 'lesson'
///   attached_to_id   = '<courseId>:<lessonId>'
///
/// The context keeps that database-specific encoding out of the UI
/// and presenter code.
class NoteContext {
  final String courseId;
  final String lessonId;

  const NoteContext({
    required this.courseId,
    required this.lessonId,
  });

  @override
  String toString() {
    return 'NoteContext(courseId: $courseId, lessonId: $lessonId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NoteContext &&
            other.courseId == courseId &&
            other.lessonId == lessonId;
  }

  @override
  int get hashCode => Object.hash(
        courseId,
        lessonId,
      );
}

