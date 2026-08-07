import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/user.dart';
import '../../../core/services/supabase_service.dart';

import '../../auth/model/user_repository.dart';
import '../../auth/presenter/auth_presenter.dart';

import '../../learning/view/course_catalog_screen.dart';
import '../../progress/view/progress_screen.dart';
import '../../profile/view/profile_screen.dart';
import '../../settings/view/settings_screen.dart';
import '../../tutor/view/tutor_dashboard_screen.dart';
import '../../admin/view/admin_dashboard_screen.dart';

/// A single destination in the shell's navigation.
class _ShellDestination {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;

  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
  });
}

/// Breakpoint below which we use a bottom nav bar; at or above it we use a
/// side navigation rail instead.
const double _kDesktopBreakpoint = 700;

/// Root authenticated shell. Wraps Home / Courses / Progress / Profile /
/// Settings, plus role-specific tabs (Tutor, Admin) once we know who's
/// signed in. Renders as a bottom nav bar on narrow screens and a side rail
/// on wide ones.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late final AuthPresenter _authPresenter;

  User? _currentUser;
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][SHELL] App shell initialized');
    _authPresenter = getIt<AuthPresenter>();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // Offline / no session: fall back to the default (student) tab set
    // rather than blocking the shell from rendering at all.
    if (!SupabaseService.instance.isReady) {
      debugPrint('[UI][SHELL] Supabase offline — using guest/student tabs');
      setState(() => _loadingUser = false);
      return;
    }

    final authUser = SupabaseService.instance.client.auth.currentUser;
    if (authUser == null) {
      debugPrint('[UI][SHELL] No authenticated user — using guest/student tabs');
      setState(() => _loadingUser = false);
      return;
    }

    try {
      final userRepository = getIt<UserRepository>();
      final user = await userRepository.findById(authUser.id);
      debugPrint('[UI][SHELL] Loaded profile with role: ${user?.role}');
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _loadingUser = false;
      });
    } catch (e) {
      debugPrint('[ERROR][UI][SHELL] Failed to load profile: $e');
      if (!mounted) return;
      setState(() => _loadingUser = false);
    }
  }

  List<_ShellDestination> get _destinations {
    final destinations = <_ShellDestination>[
      const _ShellDestination(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        page: CourseCatalogScreen(),
      ),
      const _ShellDestination(
        label: 'Courses',
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        page: CourseCatalogScreen(),
      ),
      const _ShellDestination(
        label: 'Progress',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
        page: ProgressScreen(),
      ),
      const _ShellDestination(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        page: ProfileScreen(),
      ),
      const _ShellDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        page: SettingsScreen(),
      ),
    ];

    final role = _currentUser?.role;

    if (role == User.roleTutor || role == User.roleAdmin) {
      destinations.add(
        const _ShellDestination(
          label: 'Teaching',
          icon: Icons.school_outlined,
          selectedIcon: Icons.school,
          page: TutorDashboardScreen(),
        ),
      );
    }

    if (role == User.roleAdmin) {
      destinations.add(
        const _ShellDestination(
          label: 'Admin',
          icon: Icons.admin_panel_settings_outlined,
          selectedIcon: Icons.admin_panel_settings,
          page: AdminDashboardScreen(),
        ),
      );
    }

    return destinations;
  }

  void _onDestinationSelected(int index) {
    debugPrint('[UI][SHELL] Tab selected: $index');
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = _destinations;
    // Guard against a stale index if the destination list shrinks
    // (e.g. role changed after a re-login).
    final safeIndex =
        _selectedIndex < destinations.length ? _selectedIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: constraints.maxWidth >= 1000
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  extended: constraints.maxWidth >= 1000,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Icon(Icons.school, size: 32),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: safeIndex,
                    children: [for (final d in destinations) d.page],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: [for (final d in destinations) d.page],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}