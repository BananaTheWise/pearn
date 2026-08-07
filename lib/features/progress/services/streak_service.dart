import '../../../core/models/user.dart';
import '../../auth/model/user_repository.dart';

class StreakService {
  final UserRepository _userRepository;

  StreakService({
    required UserRepository userRepository,
  }) : _userRepository = userRepository;

  /// Updates the user's streak based on their last activity date.
  User applyStreakUpdate(User user) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastActive = user.lastActiveDate;

    // First activity ever.
    if (lastActive == null) {
      return _updateUser(
        user,
        currentStreak: 1,
        longestStreak:
            user.longestStreak < 1 ? 1 : user.longestStreak,
        lastActiveDate: today,
      );
    }

    final lastDay = DateTime(
      lastActive.year,
      lastActive.month,
      lastActive.day,
    );

    final difference = today.difference(lastDay).inDays;

    // Already active today.
    if (difference == 0) {
      return user;
    }

    // Active yesterday -> continue streak.
    if (difference == 1) {
      final newStreak = user.currentStreak + 1;

      return _updateUser(
        user,
        currentStreak: newStreak,
        longestStreak: newStreak > user.longestStreak
            ? newStreak
            : user.longestStreak,
        lastActiveDate: today,
      );
    }

    // Missed one or more days -> restart streak.
    return _updateUser(
      user,
      currentStreak: 1,
      longestStreak:
          user.longestStreak < 1 ? 1 : user.longestStreak,
      lastActiveDate: today,
    );
  }

  /// Returns the user's current streak.
  Future<int> getCurrentStreak(String userId) async {
    final user = await _userRepository.findById(userId);

    if (user == null) {
      throw Exception('User profile not found');
    }

    return user.currentStreak;
  }

  User _updateUser(
    User user, {
    required int currentStreak,
    required int longestStreak,
    required DateTime lastActiveDate,
  }) {
    return User(
      id: user.id,
      username: user.username,
      role: user.role,
      status: user.status,
      totalXp: user.totalXp,
      currentLevel: user.currentLevel,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastActiveDate: lastActiveDate,
      createdAt: user.createdAt,
    );
  }
}