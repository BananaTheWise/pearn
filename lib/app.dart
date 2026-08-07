import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'core/di.dart';
import 'core/services/theme_service.dart';
import 'core/services/supabase_service.dart';
import 'core/utils/platform_utils.dart';

import 'features/auth/view/login_screen.dart';
import 'features/auth/view/signup_screen.dart';

import 'features/shell/view/app_shell.dart';

import 'features/learning/view/course_catalog_screen.dart';
import 'features/learning/view/course_detail_screen.dart';
import 'features/learning/view/lesson_screen.dart';
import 'features/learning/view/exercise_screen.dart';
import 'features/learning/view/exam_screen.dart';

import 'features/progress/view/progress_screen.dart';
import 'features/progress/view/roadmap_screen.dart';

import 'features/notes/model/note_context.dart';
import 'features/notes/view/notes_list_screen.dart';
import 'features/notes/view/note_editor_screen.dart';

import 'features/profile/view/profile_screen.dart';
import 'features/profile/view/edit_profile_screen.dart';

import 'features/settings/view/settings_screen.dart';

import 'features/tutor/view/tutor_dashboard_screen.dart';
import 'features/tutor/view/course_editor_screen.dart';

import 'features/admin/view/admin_dashboard_screen.dart';
import 'features/admin/view/review_queue_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[APP] Application widget initialized');

    final themeService = getIt<ThemeService>();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Pearn',
          debugShowCheckedModeBanner: false,

          themeMode: themeMode,

          theme: ThemeData.light().copyWith(
            useMaterial3: true,
          ),

          darkTheme: ThemeData.dark().copyWith(
            useMaterial3: true,
          ),

          initialRoute: '/splash',
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    debugPrint('[APP][ROUTER] Route requested: ${settings.name}');

    switch (settings.name) {
      // ------------------------------------------------------------
      // AUTH
      // ------------------------------------------------------------

      case '/splash':
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case '/signup':
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
        );

      // ------------------------------------------------------------
      // LEARNING
      // ------------------------------------------------------------

      case '/home':
        return MaterialPageRoute(
          builder: (_) => const AppShell(),
        );

      case '/courses':
        return MaterialPageRoute(
          builder: (_) => const CourseCatalogScreen(),
        );

      case '/course-detail':
        final courseId = settings.arguments as String?;

        if (courseId == null) {
          return _errorRoute('Course ID is missing.');
        }

        return MaterialPageRoute(
          builder: (_) => CourseDetailScreen(
            courseId: courseId,
          ),
        );

      case '/lesson':
        final args = settings.arguments as Map<String, String>?;

        if (args == null ||
            args['courseId'] == null ||
            args['lessonId'] == null) {
          return _errorRoute('Lesson information is missing.');
        }

        return MaterialPageRoute(
          builder: (_) => LessonScreen(
            courseId: args['courseId']!,
            lessonId: args['lessonId']!,
          ),
        );

      case '/exercise':
        final args = settings.arguments as Map<String, String>?;

        if (args == null ||
            args['courseId'] == null ||
            args['lessonId'] == null ||
            args['exerciseId'] == null) {
          return _errorRoute('Exercise information is missing.');
        }

        return MaterialPageRoute(
          builder: (_) => ExerciseScreen(
            courseId: args['courseId']!,
            lessonId: args['lessonId']!,
            exerciseId: args['exerciseId']!,
          ),
        );

      case '/exam':
        final examId = settings.arguments as String? ?? '';

        return MaterialPageRoute(
          builder: (_) => ExamScreen(
            examId: examId,
          ),
        );

      // ------------------------------------------------------------
      // PROGRESS
      // ------------------------------------------------------------

      case '/progress':
        return MaterialPageRoute(
          builder: (_) => const ProgressScreen(),
        );

      case '/roadmap':
        return MaterialPageRoute(
          builder: (_) => const RoadmapScreen(),
        );

      // ------------------------------------------------------------
      // NOTES
      // ------------------------------------------------------------

      case '/notes':
        return MaterialPageRoute(
          builder: (_) => const NotesListScreen(),
        );

      case '/note-editor':
        final noteContext =
            settings.arguments as Map<String, String>?;

        if (noteContext != null &&
            noteContext['courseId'] != null &&
            noteContext['lessonId'] != null) {
          return MaterialPageRoute(
            builder: (_) => NoteEditorScreen(
              noteContext: NoteContext(
                courseId: noteContext['courseId']!,
                lessonId: noteContext['lessonId']!,
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => const NotesListScreen(),
        );

      // ------------------------------------------------------------
      // PROFILE
      // ------------------------------------------------------------

      case '/profile':
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      case '/edit-profile':
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
        );

      // ------------------------------------------------------------
      // SETTINGS
      // ------------------------------------------------------------

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );

      // ------------------------------------------------------------
      // TUTOR
      // ------------------------------------------------------------

      case '/tutor-dashboard':
        if (PlatformUtils.isMobile) return _desktopOnlyRoute();
        return MaterialPageRoute(
          builder: (_) => const TutorDashboardScreen(),
        );

      case '/tutor-course-editor':
        if (PlatformUtils.isMobile) return _desktopOnlyRoute();
        final courseId = settings.arguments as String?;

        return MaterialPageRoute(
          builder: (_) => TutorCourseEditorScreen(
            courseId: courseId,
          ),
        );

      // ------------------------------------------------------------
      // ADMIN
      // ------------------------------------------------------------

      case '/admin-dashboard':
        if (PlatformUtils.isMobile) return _desktopOnlyRoute();
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
        );

      case '/admin-course-review':
        if (PlatformUtils.isMobile) return _desktopOnlyRoute();
        return MaterialPageRoute(
          builder: (_) => const ReviewQueueScreen(),
        );

      // ------------------------------------------------------------
      // UNKNOWN ROUTE
      // ------------------------------------------------------------

      default:
        return _errorRoute(
          'Unknown route: ${settings.name}',
        );
    }
  }

  Route<dynamic> _desktopOnlyRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Not available')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Admin and tutor tools are only available on desktop.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OFFLINE SPLASH SCREEN
// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    _startApplication();
  }

  Future<void> _startApplication() async {
    debugPrint('[SPLASH] Starting offline application');

    // Give the application a small amount of time to initialize.
    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    // If Supabase never came online (e.g. no internet), fall back to
    // offline/guest mode rather than blocking the user with a login screen
    // they have no way to satisfy.
    if (!SupabaseService.instance.isReady) {
      debugPrint('[SPLASH] Supabase unavailable — continuing offline as guest');
      Navigator.of(context).pushReplacementNamed('/home');
      return;
    }

    final hasSession =
        SupabaseService.instance.client.auth.currentSession != null;

    if (hasSession) {
      debugPrint('[SPLASH] Existing session found');
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      debugPrint('[SPLASH] No session — routing to login');
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}