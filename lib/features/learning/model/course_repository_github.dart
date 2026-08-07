import 'package:flutter/foundation.dart';

import '../../../core/services/github_service.dart';
import '../../../features/learning/model/chapter.dart';
import '../../../features/learning/model/course.dart';
import '../../../features/learning/model/exam.dart';
import '../../../features/learning/model/exercise.dart';
import '../../../features/learning/model/lesson.dart';
import 'course_repository.dart';

/// Concrete implementation of [CourseRepository] that fetches static learning
/// content from the GitHub repository via [GithubService].
class CourseRepositoryGithub implements CourseRepository {
  final GithubService _githubService;

  CourseRepositoryGithub(this._githubService);

  // ---------------------------------------------------------------------------
  // listCourses
  // ---------------------------------------------------------------------------
  @override
  Future<List<Course>> listCourses() async {
    debugPrint('[REPOSITORY][COURSE] Loading courses');

    try {
      final folders = await _githubService.listCourseFolders();
      debugPrint('[REPOSITORY][COURSE] Course folders received: ${folders.length}');

      final courses = <Course>[];
      for (final folder in folders) {
        try {
          debugPrint('[GITHUB] Fetching course metadata');
          final courseJson =
              await _githubService.fetchJson('courses/$folder/course.json');
          courses.add(Course.fromMap(courseJson));
        } catch (e) {
          debugPrint('[ERROR][COURSE] Failed to load course $folder: $e');
          // Skip malformed courses and continue with others.
        }
      }

      debugPrint('[REPOSITORY][COURSE] Courses loaded: ${courses.length}');
      return courses;
    } catch (e) {
      debugPrint('[ERROR][COURSE] listCourses failed');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // getCourse
  // ---------------------------------------------------------------------------
  @override
  Future<Course?> getCourse(String courseId) async {
    debugPrint('[REPOSITORY][COURSE] Loading course: $courseId');

    try {
      debugPrint('[GITHUB] Fetching course metadata');
      final courseJson =
          await _githubService.fetchJson('courses/$courseId/course.json');
      final course = Course.fromMap(courseJson);
      debugPrint('[REPOSITORY][COURSE] Course loaded');
      return course;
    } catch (e) {
      debugPrint('[ERROR][COURSE] Failed to load course $courseId: $e');
      return null; // return null if course not found or broken
    }
  }

  // ---------------------------------------------------------------------------
  // getChapters
  // ---------------------------------------------------------------------------
  @override
  Future<List<Chapter>> getChapters(String courseId) async {
    debugPrint('[REPOSITORY][COURSE] Loading chapters for $courseId');

    try {
      // The chapters are defined inside course.json
      final courseJson =
          await _githubService.fetchJson('courses/$courseId/course.json');
      final course = Course.fromMap(courseJson);
      debugPrint('[REPOSITORY][COURSE] Chapters loaded: ${course.chapters.length}');
      return course.chapters;
    } catch (e) {
      debugPrint('[ERROR][COURSE] Failed to load chapters for $courseId: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // getLesson
  // ---------------------------------------------------------------------------
  @override
  Future<Lesson?> getLesson(String courseId, String lessonId) async {
    debugPrint('[REPOSITORY][LESSON] Loading lesson $lessonId in $courseId');

    try {
      // Locate the chapter that contains this lesson.
      final chapters = await getChapters(courseId);
      Chapter? parentChapter;
      ChapterLesson? lessonInfo;

      for (final chapter in chapters) {
        lessonInfo = chapter.lessons.cast<ChapterLesson?>().firstWhere(
              (l) => l!.id == lessonId,
              orElse: () => null,
            );
        if (lessonInfo != null) {
          parentChapter = chapter;
          break;
        }
      }

      if (parentChapter == null || lessonInfo == null) {
        debugPrint('[REPOSITORY][LESSON] Lesson not found in course structure');
        return null;
      }

      // Build the GitHub path: courses/{courseId}/{chapterId}/{lessonId}.md
      final path = 'courses/$courseId/${parentChapter.id}/$lessonId.md';

      debugPrint('[GITHUB] Fetching Markdown lesson');
      final markdownContent = await _githubService.fetchMarkdown(path);

      final lesson = Lesson(
        id: lessonInfo.id,
        title: lessonInfo.title,
        chapterId: parentChapter.id,
        content: markdownContent,
        order: lessonInfo.order,
      );

      debugPrint('[REPOSITORY][LESSON] Lesson loaded');
      return lesson;
    } catch (e) {
      debugPrint('[ERROR][LESSON] Failed to load lesson $lessonId in $courseId: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // getExercises
  // ---------------------------------------------------------------------------
  @override
  Future<List<Exercise>> getExercises(String courseId, String lessonId) async {
    debugPrint('[REPOSITORY][EXERCISES] Loading exercises for lesson $lessonId in $courseId');

    try {
      // Determine the chapter that owns this lesson.
      final chapters = await getChapters(courseId);
      Chapter? parentChapter;

      for (final chapter in chapters) {
        if (chapter.lessons.any((l) => l.id == lessonId)) {
          parentChapter = chapter;
          break;
        }
      }

      if (parentChapter == null) {
        debugPrint('[REPOSITORY][EXERCISES] No chapter found for lesson');
        return [];
      }

      // Load the exercises.json file from the chapter folder.
      final path = 'courses/$courseId/${parentChapter.id}/exercises.json';
      final json = await _githubService.fetchJson(path);

      // The JSON is expected to be a map with an "exercises" key containing a list.
      final exercisesData = json['exercises'];
      if (exercisesData is! List) {
        debugPrint('[REPOSITORY][EXERCISES] Unexpected exercises format');
        return [];
      }

      final exercises = exercisesData
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList();

      debugPrint('[REPOSITORY][EXERCISES] Exercises loaded: ${exercises.length}');
      return exercises;
    } catch (e) {
      debugPrint('[ERROR][EXERCISES] Failed to load exercises: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // getExam
  // ---------------------------------------------------------------------------
  @override
  Future<Exam?> getExam(String courseId) async {
    debugPrint('[REPOSITORY][EXAM] Loading exam for $courseId');

    try {
      final path = 'courses/$courseId/exam.json';
      final json = await _githubService.fetchJson(path);
      final exam = Exam.fromMap(json);
      debugPrint('[REPOSITORY][EXAM] Exam loaded');
      return exam;
    } catch (e) {
      debugPrint('[ERROR][EXAM] Failed to load exam for $courseId: $e');
      return null;
    }
  }
}