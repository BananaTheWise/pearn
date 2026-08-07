import 'package:flutter/foundation.dart';

import '../../auth/model/user_repository.dart';
import '../../core/models/user.dart';

/// Manages daily learning streak calculations.
///
/// The streak is based on consecutive days with at least one learning activity.
/// Multiple activities on the same day count as a single qualifying day.
///
/// Date comparisons use **UTC** truncated to calendar days to avoid timezone
/// inconsistencies.
class StreakService {
  final UserRepository _userRepository;

  StreakService({required UserRepository userRepository})
      : _userRepository = userRepository;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the current streak for the given user by reading their profile.
  ///
  /// Returns `0` if the profile does not exist or the field is not available.
  Future<int> getCurrentStreak(String userId) async {
    debugPrint('[STREAK] Fetching current streak');
    final user = await _userRepository.findById(userId);
    return user?.currentStreak ?? 0;
  }

  /// Records a learning activity for the given user on the current day.
  ///
  /// Updates the user's `last_active_date`, `current_streak` and
  /// `longest_streak` fields according to the following rules:
  ///
  /// - First activity ever → streak = 1.
  /// - Activity on the next calendar day → streak increased by 1.
  /// - Activity on the same calendar day → streak unchanged.
  /// - Activity after a gap of ≥2 days → streak reset to 1.
  /// - Longest streak is updated if the new streak exceeds it.
  ///
  /// This method is idempotent for the same day.
  Future<void> recordLearningActivity(String userId) async {
    debugPrint('[STREAK] Recording learning activity');
    debugPrint('[STREAK] Calculating streak');

    // 1. Retrieve user profile – must exist.
    final user = await _userRepository.findById(userId);
    if (user == null) {
      debugPrint('[ERROR][STREAK] User profile not found');
      throw Exception('User profile not found – cannot record activity.');
    }

    // 2. Determine the current UTC day (time truncated to midnight).
    final nowUtc = DateTime.now().toUtc();
    final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

    // 3. Get the previous last active day (truncated if exists).
    final lastActiveDate = user.lastActiveDate;
    final DateTime? lastActiveDay = lastActiveDate != null
        ? DateTime.utc(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day)
        : null;

    // 4. Calculate new streak and longest.
    int newStreak;
    int newLongest = user.longestStreak;

    if (lastActiveDay == null) {
      // First activity ever.
      newStreak = 1;
    } else if (lastActiveDay == todayUtc) {
      // Already active today – streak unchanged.
      debugPrint('[STREAK] Activity already recorded for today');
      return; // Nothing to change.
    } else {
      final difference = todayUtc.difference(lastActiveDay).inDays;
      if (difference == 1) {
        // Consecutive day.
        newStreak = user.currentStreak + 1;
        debugPrint('[STREAK] Last activity date loaded – consecutive day');
      } else {
        // Gap – streak broken.
        newStreak = 1;
        debugPrint('[STREAK] Streak broken – resetting');
      }
    }

    // Update longest streak if needed.
    if (newStreak > newLongest) {
      newLongest = newStreak;
    }

    debugPrint('[STREAK] Current streak calculated: $newStreak');

    // 5. Persist changes.
    final updatedUser = user.copyWith(
      lastActiveDate: todayUtc,
      currentStreak: newStreak,
      longestStreak: newLongest,
    );

    await _userRepository.save(updatedUser);

    debugPrint('[STREAK] Learning activity recorded');
  }
}

// Minimal copyWith extension on User for internal use inside the service.
// (Prevents polluting the pure model with service-specific methods.)
extension _UserCopy on User {
  User copyWith({
    DateTime? lastActiveDate,
    int? currentStreak,
    int? longestStreak,
  }) {
    return User(
      id: id,
      username: username,
      role: role,
      status: status,
      totalXp: totalXp,
      currentLevel: currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt,
    );
  }
}