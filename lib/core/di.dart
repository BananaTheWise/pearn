import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Services ───────────────────────────────────────────────
import 'services/supabase_service.dart';
import 'services/github_service.dart';
import 'services/google_auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/theme_service.dart';
import 'services/course_id_resolver.dart';

// ─── Auth feature ──────────────────────────────────────────
import '../features/auth/model/auth_service.dart';
import '../features/auth/model/auth_service_supabase.dart';
import '../features/auth/model/user_repository.dart';
import '../features/auth/model/user_repository_supabase.dart';
import '../features/auth/presenter/auth_presenter.dart';

// ─── Learning feature ──────────────────────────────────────
import '../features/learning/model/course_repository.dart';
import '../features/learning/model/course_repository_github.dart';

import '../features/learning/model/enrollment_repository.dart';
import '../features/learning/model/enrollment_repository_supabase.dart';

import '../features/learning/model/exam_attempt_repository.dart';
import '../features/learning/model/exam_attempt_repository_supabase.dart';

import '../features/learning/presenter/course_catalog_presenter.dart';
import '../features/learning/presenter/course_detail_presenter.dart';
import '../features/learning/presenter/lesson_presenter.dart';
import '../features/learning/presenter/exercise_presenter.dart';
import '../features/learning/presenter/exam_presenter.dart';

// ─── Progress & Roadmap ────────────────────────────────────
import '../features/progress/model/progress_repository.dart';
import '../features/progress/model/progress_repository_supabase.dart';
import '../features/progress/model/roadmap_repository.dart';
import '../features/progress/model/roadmap_repository_supabase.dart';
import '../features/progress/services/streak_service.dart';
import '../features/progress/services/progress_service.dart';
import '../features/progress/presenter/progress_presenter.dart';
import '../features/progress/presenter/roadmap_presenter.dart';

// ─── Notes ─────────────────────────────────────────────────
import '../features/notes/model/note_repository.dart';
import '../features/notes/model/note_repository_supabase.dart';
import '../features/notes/presenter/note_presenter.dart';

// ─── Reactions ─────────────────────────────────────────────
import '../features/reactions/model/reaction_repository.dart';
import '../features/reactions/model/reaction_repository_supabase.dart';

// ─── Profile & Settings ───────────────────────────────────
import '../features/profile/presenter/profile_presenter.dart';
import '../features/profile/presenter/edit_profile_presenter.dart';
import '../features/settings/presenter/settings_presenter.dart';

// ─── Tutor ─────────────────────────────────────────────────
import '../features/tutor/model/tutor_repository.dart';
import '../features/tutor/model/tutor_repository_supabase.dart';
import '../features/tutor/presenter/tutor_analytics_presenter.dart';
import '../features/tutor/presenter/tutor_course_editor_presenter.dart';

// ─── Admin ─────────────────────────────────────────────────
import '../features/admin/model/admin_repository.dart';
import '../features/admin/model/admin_repository_supabase.dart';
import '../features/admin/presenter/admin_dashboard_presenter.dart';
import '../features/admin/presenter/admin_course_presenter.dart';
import '../features/admin/presenter/admin_user_presenter.dart';
import '../features/admin/presenter/admin_tutor_presenter.dart';
import '../features/admin/presenter/admin_system_presenter.dart';
import '../features/admin/presenter/admin_analytics_presenter.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  debugPrint('[DI] Starting dependency registration');

  try {
    // 1. Infrastructure services
    _registerServices();

    // 2. Repositories
    _registerRepositories();

    // 3. Domain services
    _registerDomainServices();

    // 4. Presenters
    _registerPresenters();

    debugPrint('[DI] Dependency registration completed');
  } catch (e) {
    debugPrint('[ERROR][DI] Dependency registration failed');
    debugPrint('Reason: ${e.runtimeType}');
    rethrow;
  }
}

// ────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────

String _currentUserId() {
  return Supabase.instance.client.auth.currentUser?.id ?? '';
}

// ────────────────────────────────────────────────────────────
// 1. Services
// ────────────────────────────────────────────────────────────

void _registerServices() {
  debugPrint('[DI] Registering SupabaseService');
  getIt.registerSingleton(SupabaseService.instance);

  debugPrint('[DI] Registering GithubService');
  getIt.registerLazySingleton<GithubService>(
    () => GithubService(),
  );

  debugPrint('[DI] Registering GoogleAuthService');
  getIt.registerLazySingleton<GoogleAuthService>(
    () => GoogleAuthService(),
  );

  debugPrint('[DI] Registering ConnectivityService');
  getIt.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(),
  );

  debugPrint('[DI] Registering ThemeService');
  getIt.registerSingleton(ThemeService());

  debugPrint('[DI] Registering CourseIdResolver');
  getIt.registerLazySingleton<CourseIdResolver>(
    () => CourseIdResolver(getIt()),
  );
}

// ────────────────────────────────────────────────────────────
// 2. Repositories
// ────────────────────────────────────────────────────────────

void _registerRepositories() {
  debugPrint('[DI] Registering repositories');

  // ─── User ────────────────────────────────────────────────
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositorySupabase(getIt()),
  );

  // ─── Auth ────────────────────────────────────────────────
  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceSupabase(
      supabaseService: getIt(),
      googleAuthService: getIt(),
      userRepository: getIt(),
    ),
  );

  // ─── Enrollment ──────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentRepository>(
    () => EnrollmentRepositorySupabase(getIt(), getIt()),
  );

  // ─── Courses → GitHub ───────────────────────────────────
  getIt.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryGithub(getIt()),
  );

  // ─── Exams ───────────────────────────────────────────────
  getIt.registerLazySingleton<ExamAttemptRepository>(
    () => ExamAttemptRepositorySupabase(getIt()),
  );

  // ─── Progress ────────────────────────────────────────────
  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositorySupabase(getIt(), getIt()),
  );

  // ─── Roadmap ─────────────────────────────────────────────
  getIt.registerLazySingleton<RoadmapRepository>(
    () => RoadmapRepositorySupabase(getIt()),
  );

  // ─── Notes ───────────────────────────────────────────────
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepositorySupabase(
      supabaseService: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Reactions ───────────────────────────────────────────
  getIt.registerLazySingleton<ReactionRepository>(
    () => ReactionRepositorySupabase(getIt()),
  );

  // ─── Tutor ───────────────────────────────────────────────
  getIt.registerLazySingleton<TutorRepository>(
    () => TutorRepositorySupabase(
      supabaseService: getIt(),
      githubService: getIt(),
      userRepository: getIt(),
    ),
  );

  // ─── Admin ───────────────────────────────────────────────
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepositorySupabase(
      supabaseService: getIt(),
      githubService: getIt(),
    ),
  );
}

// ────────────────────────────────────────────────────────────
// 3. Domain services
// ────────────────────────────────────────────────────────────

void _registerDomainServices() {
  debugPrint('[DI] Registering domain services');

  getIt.registerLazySingleton<StreakService>(
    () => StreakService(
      userRepository: getIt(),
    ),
  );

  debugPrint('[DI] Registering ProgressService');
  getIt.registerLazySingleton<ProgressService>(
    () => ProgressService(
      userRepository: getIt(),
      progressRepository: getIt(),
      streakService: getIt(),
    ),
  );
}

// ────────────────────────────────────────────────────────────
// 4. Presenters
// ────────────────────────────────────────────────────────────

void _registerPresenters() {
  debugPrint('[DI] Registering presenters');

  // ─── Auth ────────────────────────────────────────────────
  getIt.registerFactory<AuthPresenter>(
    () => AuthPresenter(
      authService: getIt(),
    ),
  );

  // ─── Course Catalog ─────────────────────────────────────
  getIt.registerFactory<CourseCatalogPresenter>(
    () => CourseCatalogPresenter(
      courseRepo: getIt(),
    ),
  );

  // ─── Course Detail ──────────────────────────────────────
  getIt.registerFactory<CourseDetailPresenter>(
    () => CourseDetailPresenter(
      courseRepo: getIt(),
      reactionRepo: getIt(),
      enrollmentRepo: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Lesson ──────────────────────────────────────────────
  getIt.registerFactory<LessonPresenter>(
    () => LessonPresenter(
      courseRepo: getIt(),
      userId: _currentUserId(),
      progressService: getIt(),
    ),
  );

  // ─── Exercise ────────────────────────────────────────────
  getIt.registerFactory<ExercisePresenter>(
    () => ExercisePresenter(
      courseRepo: getIt(),
    ),
  );

  // ─── Exam ────────────────────────────────────────────────
  getIt.registerFactory<ExamPresenter>(
    () => ExamPresenter(
      courseRepo: getIt(),
      examAttemptRepo: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Progress ────────────────────────────────────────────
  getIt.registerFactory<ProgressPresenter>(
    () => ProgressPresenter(
      progressRepository: getIt(),
      streakService: getIt(),
      userRepository: getIt(),
      enrollmentRepository: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Roadmap ─────────────────────────────────────────────
  getIt.registerFactory<RoadmapPresenter>(
    () => RoadmapPresenter(
      roadmapRepository: getIt(),
      userId: _currentUserId(),
      progressRepository: getIt(),
    ),
  );

  // ─── Notes ───────────────────────────────────────────────
  getIt.registerFactory<NotePresenter>(
    () => NotePresenter(
      noteRepository: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Profile ─────────────────────────────────────────────
  getIt.registerFactory<ProfilePresenter>(
    () => ProfilePresenter(
      userRepository: getIt(),
      authService: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Edit Profile ───────────────────────────────────────
  getIt.registerFactory<EditProfilePresenter>(
    () => EditProfilePresenter(
      userRepository: getIt(),
      userId: _currentUserId(),
    ),
  );

  // ─── Settings ────────────────────────────────────────────
  getIt.registerFactory<SettingsPresenter>(
    () => SettingsPresenter(
      authService: getIt(),
      themeService: getIt(),
    ),
  );

  // ─── Tutor Analytics ────────────────────────────────────
  getIt.registerFactory<TutorAnalyticsPresenter>(
    () => TutorAnalyticsPresenter(
      tutorRepository: getIt(),
      tutorId: _currentUserId(),
    ),
  );

  // ─── Tutor Course Editor ─────────────────────────────────
  getIt.registerFactory<TutorCourseEditorPresenter>(
    () => TutorCourseEditorPresenter(
      tutorRepository: getIt(),
      tutorId: _currentUserId(),
    ),
  );

  // ─── Admin Dashboard ─────────────────────────────────────
  getIt.registerFactory<AdminDashboardPresenter>(
    () => AdminDashboardPresenter(
      adminRepository: getIt(),
      currentUserId: _currentUserId(),
    ),
  );

  // ─── Admin Course ────────────────────────────────────────
  getIt.registerFactory<AdminCoursePresenter>(
    () => AdminCoursePresenter(
      adminRepo: getIt(),
    ),
  );

  // ─── Admin User ──────────────────────────────────────────
  getIt.registerFactory<AdminUserPresenter>(
    () => AdminUserPresenter(
      adminRepo: getIt(),
    ),
  );

  // ─── Admin Tutor ─────────────────────────────────────────
  getIt.registerFactory<AdminTutorPresenter>(
    () => AdminTutorPresenter(
      adminRepo: getIt(),
    ),
  );

  // ─── Admin System ────────────────────────────────────────
  getIt.registerFactory<AdminSystemPresenter>(
    () => AdminSystemPresenter(
      adminRepository: getIt(),
      connectivityService: getIt(),
    ),
  );

  // ─── Admin Analytics ─────────────────────────────────────
  getIt.registerFactory<AdminAnalyticsPresenter>(
    () => AdminAnalyticsPresenter(
      adminRepo: getIt(),
    ),
  );
}