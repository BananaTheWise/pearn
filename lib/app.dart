import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'core/di.dart';
import 'core/services/theme_service.dart';
import 'features/auth/model/auth_service.dart';
import 'features/auth/view/login_screen.dart';
import 'features/auth/view/signup_screen.dart';
import 'features/learning/view/course_catalog_screen.dart';
import 'features/learning/view/course_detail_screen.dart';
import 'features/learning/view/lesson_screen.dart';
import 'features/learning/view/exercise_screen.dart';
import 'features/learning/view/exam_screen.dart';
import 'features/progress/view/progress_screen.dart';
import 'features/progress/view/roadmap_screen.dart';
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
          title: 'Learning Platform',
          themeMode: themeMode,
          theme: ThemeData.light().copyWith(
            // Customize light theme if needed
          ),
          darkTheme: ThemeData.dark().copyWith(
            // Customize dark theme if needed
          ),
          initialRoute: '/splash',
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    debugPrint('[APP][ROUTER] Route requested: ${settings.name}');

    // Helper to wrap a screen with authentication check.
    // For simplicity, we rely on AuthService stream to redirect globally.
    // Individual screens do not need to check again.

    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case '/home':
        // Home could be a shell with bottom navigation, or directly course catalog.
        return MaterialPageRoute(builder: (_) => const CourseCatalogScreen());
      case '/courses':
        return MaterialPageRoute(builder: (_) => const CourseCatalogScreen());
      case '/course-detail':
        final courseId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: courseId),
        );
      case '/lesson':
        final args = settings.arguments as Map<String, String>;
        return MaterialPageRoute(
          builder: (_) => LessonScreen(
            courseId: args['courseId']!,
            lessonId: args['lessonId']!,
          ),
        );
      case '/exercise':
        final args = settings.arguments as Map<String, String>;
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
          builder: (_) => ExamScreen(examId: examId),
        );
      case '/progress':
        return MaterialPageRoute(builder: (_) => const ProgressScreen());
      case '/roadmap':
        return MaterialPageRoute(builder: (_) => const RoadmapScreen());
      case '/notes':
        return MaterialPageRoute(builder: (_) => const NotesListScreen());
      case '/note-editor':
        final noteContext = settings.arguments as Map<String, String>?;
        if (noteContext != null) {
          // Open editor with context (create new note)
          return MaterialPageRoute(
            builder: (_) => NoteEditorScreen(
              noteContext: NoteContext(
                courseId: noteContext['courseId']!,
                lessonId: noteContext['lessonId']!,
              ),
            ),
          );
        }
        // If no arguments, maybe just open list? Fallback.
        return MaterialPageRoute(builder: (_) => const NotesListScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/tutor-dashboard':
        return MaterialPageRoute(builder: (_) => const TutorDashboardScreen());
      case '/tutor-course-editor':
        final courseId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => TutorCourseEditorScreen(courseId: courseId),
        );
      case '/admin-dashboard':
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      case '/admin-course-review':
        return MaterialPageRoute(builder: (_) => const ReviewQueueScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
        );
    }
  }
}

/// Splash screen that listens to auth state and redirects accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = getIt<AuthService>();
    final initialAuthState = authService.authStateChanges()
        .first; // wait for the first emission

    // We can't use 'await' on a stream directly; we'll subscribe.
    // A better approach is to use a StreamBuilder in the SplashScreen's build,
    // but to keep it simple we'll listen for one value.
    // Actually, we can do:
    final subscription = authService.authStateChanges().listen((state) {
      if (state == AuthState.authenticated) {
        // Navigate to home or appropriate role-based route
        _navigateToHome();
      } else if (state == AuthState.unauthenticated) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      // if loading, stay on splash
    });

    // Cancel after first emission that resolves
    subscription.onData((state) {
      if (state != AuthState.loading) {
        subscription.cancel();
      }
    });
  }

  void _navigateToHome() {
    // Determine role-based home
    final userId = getIt<SupabaseService>().client.auth.currentUser?.id;
    if (userId != null) {
      final userRepo = getIt<UserRepository>();
      userRepo.findById(userId).then((user) {
        if (user != null) {
          switch (user.role) {
            case 'admin':
              Navigator.of(context).pushReplacementNamed('/admin-dashboard');
              break;
            case 'tutor':
              Navigator.of(context).pushReplacementNamed('/tutor-dashboard');
              break;
            default:
              Navigator.of(context).pushReplacementNamed('/home');
          }
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }).catchError((_) {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}