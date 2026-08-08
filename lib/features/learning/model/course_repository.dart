import '../../../features/learning/model/chapter.dart';
import '../../../features/learning/model/course.dart';
import '../../../features/learning/model/exam.dart';
import '../../../features/learning/model/exercise.dart';
import '../../../features/learning/model/lesson.dart';

/// Abstract contract for course content repository.
///
/// The concrete implementation ([CourseRepositoryGithub]) fetches data from
/// the GitHub course repository. This interface ensures that presenters and
/// other layers remain independent of the data source.
abstract class CourseRepository {
  /// Returns all available courses.
  Future<List<Course>> listCourses();

  /// Retrieves a single course by its [courseId].
  Future<Course?> getCourse(String courseId);

  /// Returns the chapters for the specified [courseId].
  Future<List<Chapter>> getChapters(String courseId);

  /// Retrieves a lesson for the given [courseId] and [lessonId].
  Future<Lesson?> getLesson(String courseId, String lessonId);

  /// Returns exercises for a lesson or course, depending on the content structure.
  Future<List<Exercise>> getExercises(String courseId, String lessonId);

  /// Returns the exam for the specified [courseId], or `null` if none exists.
  Future<Exam?> getExam(String courseId, String examId);
}