import 'package:flutter/foundation.dart';

import '../../auth/model/user_repository.dart';
import '../../../core/models/user.dart';
import '../../progress/model/progress_repository.dart';
import '../../progress/services/streak_service.dart';

/// Central service for managing learning progress, XP, and streaks.
///
/// This service coordinates between [ProgressRepository], [UserRepository],
/// and [StreakService]. It contains all business rules for awarding XP,
/// calculating levels, and updating streaks. No direct Supabase or GitHub
/// calls are made here.
class ProgressService {
  final UserRepository _userRepository;
  final ProgressRepository _progressRepository;
  final StreakService _streakService;

  // ---------------------------------------------------------------------------
  // XP constants – adjust to match the project's requirements
  // ---------------------------------------------------------------------------
  static const int xpPerLesson = 10;
  static const int xpPerExercise = 5;
  static const int xpPerExamPass = 50;

  ProgressService({
    required UserRepository userRepository,
    required ProgressRepository progressRepository,
    required StreakService streakService,
  })  : _userRepository = userRepository,
        _progressRepository = progressRepository,
        _streakService = streakService;

  // ---------------------------------------------------------------------------
  // completeLesson
  // ---------------------------------------------------------------------------
  /// Processes the completion of a lesson for the given user and course.
  ///
  /// Awards XP, updates the user's level, records the lesson as completed,
  /// and updates the learning streak. Does nothing if the lesson is already
  /// marked as completed (prevents duplicate rewards).
  Future<void> completeLesson(
      String userId, String courseId, String lessonId) async {
    debugPrint('[SERVICE][PROGRESS] Lesson completion received');
    debugPrint('[SERVICE][PROGRESS] Checking existing completion');

    // 1. Check if already completed
    final completed =
        await _progressRepository.getCompletedLessons(userId, courseId);
    if (completed.contains(lessonId)) {
      debugPrint('[SERVICE][PROGRESS] Lesson already completed – skipping');
      return;
    }

    debugPrint('[SERVICE][PROGRESS] XP calculation started');

    try {
      // 2. Fetch user profile
      User user = await _userRepository.findById(userId) ??
          (throw Exception('User profile not found'));

      // 3. Award XP and calculate new level
      final newXp = user.totalXp + xpPerLesson;
      final newLevel = _calculateLevel(newXp);
      user = user.copyWith(totalXp: newXp, currentLevel: newLevel);

      // 4. Apply streak update (relies on StreakService's pure calculation)
      user = _streakService.applyStreakUpdate(user);

      // 5. Persist user changes
      await _userRepository.save(user);
      debugPrint('[SERVICE][PROGRESS] Progress updated');

      // 6. Mark lesson as completed in progress repository
      await _progressRepository.markLessonCompleted(
          userId, courseId, lessonId);
      debugPrint('[SERVICE][PROGRESS] Lesson marked completed');

      // 7. Record learning activity for streak (streak update is already done)
      debugPrint('[SERVICE][PROGRESS] Streak activity recorded');
      debugPrint('[SERVICE][PROGRESS] Progress operation completed');
    } catch (e) {
      debugPrint('[ERROR][SERVICE][PROGRESS] Failed to persist progress');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // completeExercise (optional – implement if required)
  // ---------------------------------------------------------------------------
  /// Processes exercise completion. Awards XP and updates streak, but does
  /// not persist a separate exercise completion record unless the architecture
  /// defines one.
  Future<void> completeExercise(
      String userId, String courseId, String exerciseId) async {
    debugPrint('[SERVICE][PROGRESS] Exercise completion received');

    try {
      User user = await _userRepository.findById(userId) ??
          (throw Exception('User profile not found'));

      final newXp = user.totalXp + xpPerExercise;
      final newLevel = _calculateLevel(newXp);
      user = user.copyWith(totalXp: newXp, currentLevel: newLevel);

      user = _streakService.applyStreakUpdate(user);

      await _userRepository.save(user);
      debugPrint('[SERVICE][PROGRESS] Exercise XP awarded and progress updated');
    } catch (e) {
      debugPrint('[ERROR][SERVICE][PROGRESS] Failed to process exercise completion');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // completeExam
  // ---------------------------------------------------------------------------
  /// Called after an exam attempt is evaluated. If the exam was passed,
  /// awards XP, updates level and streak.
  Future<void> completeExam(
      String userId, String courseId, String examId, bool passed) async {
    debugPrint('[SERVICE][PROGRESS] Exam completion received');
    if (!passed) {
      debugPrint('[SERVICE][PROGRESS] Exam not passed – no XP awarded');
      return;
    }

    try {
      User user = await _userRepository.findById(userId) ??
          (throw Exception('User profile not found'));

      final newXp = user.totalXp + xpPerExamPass;
      final newLevel = _calculateLevel(newXp);
      user = user.copyWith(totalXp: newXp, currentLevel: newLevel);

      user = _streakService.applyStreakUpdate(user);

      await _userRepository.save(user);
      debugPrint('[SERVICE][PROGRESS] Exam XP awarded and progress updated');
    } catch (e) {
      debugPrint('[ERROR][SERVICE][PROGRESS] Failed to process exam completion');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Level calculation
  // ---------------------------------------------------------------------------
  /// Derives the user's level from their total XP.
  /// This is the **single place** where level ↔ XP mapping is defined.
  static int _calculateLevel(int totalXp) {
    // Example: level = floor(totalXp / 100) + 1
    return (totalXp / 100).floor() + 1;
  }
}

// Minimal copyWith for User used internally.
// This avoids polluting the pure model with service-only mutation methods.
extension _UserProgressCopy on User {
  User copyWith({
    int? totalXp,
    int? currentLevel,
  }) {
    return User(
      id: id,
      username: username,
      role: role,
      status: status,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActiveDate: lastActiveDate,
      createdAt: createdAt,
    );
  }
}