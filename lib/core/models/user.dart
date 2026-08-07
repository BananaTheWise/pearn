import '../widgets/user_avatar.dart';
import 'package:flutter/material.dart';

/// Pure data model representing a user profile.
///
/// This class does NOT depend on Flutter, Supabase, Dio, or any other
/// service/repository. It is a plain Dart object used for data transfer
/// between repositories and presenters.
///
/// Mapped from the `profiles` database table.
class User {
  /// Unique identifier (from the `profiles.id` column).
  final String id;

  /// Display name / handle.
  final String username;

  /// Role within the platform.
  ///
  /// Allowed values: `'student'` / `'user'`, `'tutor'`, `'admin'`.
  final String role;

  /// Current account status.
  ///
  /// Allowed values: `'active'`, `'suspended'`, `'banned'`.
  final String status;

  /// Total experience points.
  final int totalXp;

  /// Current level (derived or stored).
  final int currentLevel;

  /// Consecutive days the user has been active.
  final int currentStreak;

  /// Highest consecutive-days streak ever achieved.
  final int longestStreak;

  /// Date of last activity. May be `null` for freshly created accounts.
  final DateTime? lastActiveDate;

  /// Timestamp when the profile was created.
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.role,
    required this.status,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    required this.createdAt,
  });

  // Returns a copy of this User with the given fields replaced.
  User copyWith({
    String? id,
    String? username,
    String? role,
    String? status,
    int? totalXp,
    int? currentLevel,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      status: status ?? this.status,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Creates a [User] from a raw database map (e.g. from Supabase).
  ///
  /// The map must contain all required fields.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
      totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
      currentLevel: (map['current_level'] as num?)?.toInt() ?? 1,
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: map['last_active_date'] == null
          ? null
          : DateTime.tryParse(map['last_active_date'].toString()),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  /// Converts this [User] into a map suitable for database insertion/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'status': status,
      'total_xp': totalXp,
      'current_level': currentLevel,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_active_date': lastActiveDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Role constants for readability.
  static const String roleStudent = 'student';
  static const String roleTutor = 'tutor';
  static const String roleAdmin = 'admin';

  /// Status constants.
  static const String statusActive = 'active';
  static const String statusSuspended = 'suspended';
  static const String statusBanned = 'banned';
}
