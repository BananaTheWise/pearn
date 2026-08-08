import '../../../features/learning/model/exercise.dart';
import '../../../features/learning/model/lesson.dart';

abstract class ILessonView {
  void showLoading(bool loading);

  void showLesson(Lesson lesson);

  void showError(String message);

  void markLessonCompleted();

}
