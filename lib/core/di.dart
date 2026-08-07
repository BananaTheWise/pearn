import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Services ───────────────────────────────────────────────
import 'services/supabase_service.dart';
import 'services/github_service.dart';
import 'services/google_auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/theme_service.dart';

// ─── Auth feature ──────────────────────────────────────────
import '../features/auth/model/auth_service.dart';
import '../features/auth/model/auth_service_supabase.dart';
import '../features/auth/model/user_repository.dart';
import '../features/auth/model/user_repository_supabase.dart';
import '../features/auth/presenter/auth_presenter.dart';

// ─── Learning feature (courses, lessons, exercises, exams) ─
import '../features/learning/model/course_repository.dart';
import '../features/learning/model/course_repository_github.dart';
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
import '../features/progress/presenter/progress_presenter.dart';
import '../features/progress/presenter/roadmap_presenter.dart';

// ─── Notes ─────────────────────────────────────────────────
import '../features/notes/model/note_repository.dart';
import '../features/notes/model/note_repository_supabase.dart';
import '../features/notes/presenter/note_presenter.dart';

// ─── Reactions ─────────────────────────────────────────────
import '../features/reactions/model/reaction_repository.dart';
import '../features/reactions/model/reaction_repository_supabase.dart';

// ─── Profile & Settings ────────────────────────────────────
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
import '../features/admin/presenter/admin_dashboard_presenter.dart';   // assumed name
import '../features/admin/presenter/admin_course_presenter.dart';
import '../features/admin/presenter/admin_user_presenter.dart';
import '../features/admin/presenter/admin_tutor_presenter.dart';
import '../features/admin/presenter/admin_system_presenter.dart';
import '../features/admin/presenter/admin_analytics_presenter.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  debugPrint('[DI] Starting dependency registration');

  try {
    // 1. Infrastructure services (singletons)
    _registerServices();
    // 2. Repositories (lazy singletons)
    _registerRepositories();
    // 3. Domain services (depend on repositories)
    _registerDomainServices();
    // 4. Presenters (factories – created per-screen)
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
  // At runtime, when the presenter is created, we assume the user is logged in.
  return Supabase.instance.client.auth.currentUser?.id ?? '';
}

// ────────────────────────────────────────────────────────────
// 1. Services
// ────────────────────────────────────────────────────────────
void _registerServices() {
  debugPrint('[DI] Registering SupabaseService');
  getIt.registerSingleton<SupabaseService>(SupabaseService.instance);

  debugPrint('[DI] Registering GithubService');
  getIt.registerLazySingleton<GithubService>(() => GithubService());

  debugPrint('[DI] Registering GoogleAuthService');
  getIt.registerLazySingleton<GoogleAuthService>(() => GoogleAuthService());

  debugPrint('[DI] Registering ConnectivityService');
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());

  debugPrint('[DI] Registering ThemeService');
  getIt.registerSingleton<ThemeService>(ThemeService());
}

// ────────────────────────────────────────────────────────────
// 2. Repositories
// ────────────────────────────────────────────────────────────
void _registerRepositories() {
  debugPrint('[DI] Registering repositories');

  // User
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositorySupabase(getIt<SupabaseService>()),
  );

  // AuthService (concrete)
  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceSupabase(
      supabaseService: getIt<SupabaseService>(),
      googleAuthService: getIt<GoogleAuthService>(),
      userRepository: getIt<UserRepository>(),
    ),
  );

  // Course (GitHub)
  getIt.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryGithub(getIt<GithubService>()),
  );

  // ExamAttempt
  getIt.registerLazySingleton<ExamAttemptRepository>(
    () => ExamAttemptRepositorySupabase(getIt<SupabaseService>()),
  );

  // Progress
  getIt.registerLazySingleton<ProgressRepository>(
    () => ProgressRepositorySupabase(getIt<SupabaseService>()),
  );

  // Roadmap
  getIt.registerLazySingleton<RoadmapRepository>(
    () => RoadmapRepositorySupabase(getIt<SupabaseService>()),
  );

  // Notes (requires userId for ownership enforcement)
  getIt.registerLazySingleton<NoteRepository>(
    () => NoteRepositorySupabase(
      supabaseService: getIt<SupabaseService>(),
      userId: _currentUserId(),
    ),
  );

  // Reactions
  getIt.registerLazySingleton<ReactionRepository>(
    () => ReactionRepositorySupabase(getIt<SupabaseService>()),
  );

  // Tutor
  getIt.registerLazySingleton<TutorRepository>(
    () => TutorRepositorySupabase(
      supabaseService: getIt<SupabaseService>(),
      githubService: getIt<GithubService>(),
      userRepository: getIt<UserRepository>(),
    ),
  );

  // Admin
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepositorySupabase(
      supabaseService: getIt<SupabaseService>(),
      githubService: getIt<GithubService>(),
    ),
  );
}

// ────────────────────────────────────────────────────────────
// 3. Domain services (StreakService)
// ────────────────────────────────────────────────────────────
void _registerDomainServices() {
  debugPrint('[DI] Registering domain services');

  getIt.registerLazySingleton<StreakService>(
    () => StreakService(userRepository: getIt<UserRepository>()),
  );
}

// ────────────────────────────────────────────────────────────
// 4. Presenters
// ────────────────────────────────────────────────────────────
void _registerPresenters() {
  debugPrint('[DI] Registering presenters');

  // Auth
  getIt.registerFactory<AuthPresenter>(
    () => AuthPresenter(authService: getIt<AuthService>()),
  );

  // Course Catalog
  getIt.registerFactory<CourseCatalogPresenter>(
    () => CourseCatalogPresenter(courseRepo: getIt<CourseRepository>()),
  );

  // Course Detail (with reaction support)
  getIt.registerFactory<CourseDetailPresenter>(
    () => CourseDetailPresenter(
      courseRepo: getIt<CourseRepository>(),
      reactionRepo: getIt<ReactionRepository>(),
      userId: _currentUserId(),
      enrollmentRepo: null, // TODO: implement EnrollmentRepository
    ),
  );

  // Lesson
  getIt.registerFactory<LessonPresenter>(
    () => LessonPresenter(
      courseRepo: getIt<CourseRepository>(),
      userId: _currentUserId(),
    ),
  );

  // Exercise
  getIt.registerFactory<ExercisePresenter>(
    () => ExercisePresenter(courseRepo: getIt<CourseRepository>()),
  );

  // Exam
  getIt.registerFactory<ExamPresenter>(
    () => ExamPresenter(
      courseRepo: getIt<CourseRepository>(),
      examAttemptRepo: getIt<ExamAttemptRepository>(),
      userId: _currentUserId(),
    ),
  );

  // Progress
  getIt.registerFactory<ProgressPresenter>(
    () => ProgressPresenter(
      progressRepository: getIt<ProgressRepository>(),
      streakService: getIt<StreakService>(),
      userRepository: getIt<UserRepository>(),
      enrollmentRepository: null, // TODO
      userId: _currentUserId(),
    ),
  );

  // Roadmap
  getIt.registerFactory<RoadmapPresenter>(
    () => RoadmapPresenter(
      roadmapRepository: getIt<RoadmapRepository>(),
      userId: _currentUserId(),
      progressRepository: getIt<ProgressRepository>(),
    ),
  );

  // Notes
  getIt.registerFactory<NotePresenter>(
    () => NotePresenter(
      noteRepository: getIt<NoteRepository>(),
      userId: _currentUserId(),
    ),
  );

  // Profile
  getIt.registerFactory<ProfilePresenter>(
    () => ProfilePresenter(
      userRepository: getIt<UserRepository>(),
      authService: getIt<AuthService>(),
      userId: _currentUserId(),
    ),
  );

  // Edit Profile
  getIt.registerFactory<EditProfilePresenter>(
    () => EditProfilePresenter(
      userRepository: getIt<UserRepository>(),
      userId: _currentUserId(),
    ),
  );

  // Settings
  getIt.registerFactory<SettingsPresenter>(
    () => SettingsPresenter(
      authService: getIt<AuthService>(),
      themeService: getIt<ThemeService>(),
    ),
  );

  // Tutor Analytics Dashboard
  getIt.registerFactory<TutorAnalyticsPresenter>(
    () => TutorAnalyticsPresenter(
      tutorRepository: getIt<TutorRepository>(),
      tutorId: _currentUserId(),
    ),
  );

  // Tutor Course Editor
  getIt.registerFactory<TutorCourseEditorPresenter>(
    () => TutorCourseEditorPresenter(
      tutorRepository: getIt<TutorRepository>(),
      tutorId: _currentUserId(),
    ),
  );

  // ─── Admin presenters ────────────────────────────────────
  // Dashboard (uses a composite presenter pattern; we create a single
  // "AdminDashboardPresenter" that may coordinate sub-presenters, or
  // we can register the sub-presenters directly.  For simplicity, we'll
  // register them all as factories, and the dashboard screen will
  // resolve them as needed.)

  // Admin Course Review
  getIt.registerFactory<AdminCoursePresenter>(
    () => AdminCoursePresenter(adminRepo: getIt<AdminRepository>()),
  );

  // Admin User Management
  getIt.registerFactory<AdminUserPresenter>(
    () => AdminUserPresenter(adminRepo: getIt<AdminRepository>()),
  );

  // Admin Tutor Management
  getIt.registerFactory<AdminTutorPresenter>(
    () => AdminTutorPresenter(adminRepo: getIt<AdminRepository>()),
  );

  // Admin System
  getIt.registerFactory<AdminSystemPresenter>(
    () => AdminSystemPresenter(
      adminRepository: getIt<AdminRepository>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
  );

  // Admin Analytics
  getIt.registerFactory<AdminAnalyticsPresenter>(
    () => AdminAnalyticsPresenter(adminRepo: getIt<AdminRepository>()),
  );

  // If we want a unified AdminDashboardPresenter that holds references
  // to these sub-presenters, we could create one that accepts them all.
  // For now, the AdminDashboardScreen can obtain them individually.
}