import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/user.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/platform_utils.dart';

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
  final Color? accentColor;

  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.page,
    this.accentColor,
  });
}

/// Breakpoint below which we use a bottom nav bar; at or above it we use a
/// side navigation rail instead.
const double _kDesktopBreakpoint = 700;

/// Fixed width used for the extended rail's inner content (header + footer).
/// Must match `minExtendedWidth` below, minus the 16px horizontal padding on
/// each side (200 - 32 = 168). Any widget inside the extended rail that
/// wants to fill the available width MUST use this instead of
/// `double.infinity` — NavigationRail does not give its leading/trailing
/// slots a bounded width, so `double.infinity` there throws
/// "BoxConstraints forces an infinite width" during layout.
const double _kExtendedRailContentWidth = 168;

/// Root authenticated shell. Wraps Courses / Progress / Profile / Settings,
/// plus role-specific tabs (Tutor, Admin) once we know who's signed in.
/// Renders as a bottom nav bar on narrow screens and a side rail on wide
/// ones. Sign-out lives in Settings, not in this shell.
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
      if (mounted) setState(() => _loadingUser = false);
      return;
    }

    final authUser = SupabaseService.instance.client.auth.currentUser;
    if (authUser == null) {
      debugPrint(
        '[UI][SHELL] No authenticated user — using guest/student tabs',
      );
      if (mounted) setState(() => _loadingUser = false);
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
        label: 'Courses',
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        page: CourseCatalogScreen(),
      ),
      const _ShellDestination(
        label: 'Progress',
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights_rounded,
        page: ProgressScreen(),
      ),
      const _ShellDestination(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person_rounded,
        page: ProfileScreen(),
      ),
      const _ShellDestination(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        page: SettingsScreen(),
      ),
    ];

    final role = _currentUser?.role;

    // Admin and tutor tooling is desktop-only, regardless of role.
    if (PlatformUtils.isDesktop) {
      if (role == User.roleTutor || role == User.roleAdmin) {
        destinations.add(
          const _ShellDestination(
            label: 'Teaching',
            icon: Icons.school_outlined,
            selectedIcon: Icons.school_rounded,
            page: TutorDashboardScreen(),
            accentColor: Colors.orange,
          ),
        );
      }

      if (role == User.roleAdmin) {
        destinations.add(
          const _ShellDestination(
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings_rounded,
            page: AdminDashboardScreen(),
            accentColor: Colors.red,
          ),
        );
      }
    }

    return destinations;
  }

  void _onDestinationSelected(int index) {
    debugPrint('[UI][SHELL] Tab selected: $index');
    if (index < 0 || index >= _destinations.length) return;
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUser) {
      return _buildLoadingScaffold(context);
    }

    final destinations = _destinations;
    // Guard against a stale index if the destination list shrinks
    // (e.g. role changed after a re-login).
    final safeIndex = _selectedIndex < destinations.length ? _selectedIndex : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

        if (isDesktop) {
          return _buildDesktopLayout(
            context,
            destinations,
            safeIndex,
            constraints,
          );
        }

        return _buildMobileLayout(context, destinations, safeIndex);
      },
    );
  }

  // ─── Loading State ─────────────────────────────────────────────

  Widget _buildLoadingScaffold(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/image/Pearn.png', width: 96, height: 96),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your workspace…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Desktop Layout ────────────────────────────────────────────

  Widget _buildDesktopLayout(
    BuildContext context,
    List<_ShellDestination> destinations,
    int safeIndex,
    BoxConstraints constraints,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isExtended = constraints.maxWidth >= 1000;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isExtended ? 160 : 64,
            color: colorScheme.surface,
            child: Column(
              children: [
                _buildRailHeader(context, isExtended),

                const SizedBox(height: 20),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final d = destinations[index];
                      final selected = safeIndex == index;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: selected
                              ? colorScheme.secondaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _onDestinationSelected(index),
                            child: SizedBox(
                              height: 72,
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selected ? d.selectedIcon : d.icon,
                                    color: selected
                                        ? d.accentColor ??
                                              colorScheme.onSecondaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    size: 24,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    d.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? colorScheme.onSecondaryContainer
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
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

  Widget _buildRailHeader(BuildContext context, bool isExtended) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Compact mode: simple branded logo, always safe
    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Image.asset('lib/assets/image/Pearn.png', width: 40, height: 40),
      );
    }

    final user = _currentUser;
    final displayName = user?.username ?? 'Guest';
    final role = user?.role;

    // Extended mode: fixed width container so Row/Expanded cannot overflow.
    // 168 = 200 (minExtendedWidth) - 32 (horizontal padding).
    return SizedBox(
      width: _kExtendedRailContentWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand
            Row(
              children: [
                Image.asset(
                  'lib/assets/image/Pearn.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pearn',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // User preview
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (role != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onTertiaryContainer,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Mobile Layout ─────────────────────────────────────────────

  Widget _buildMobileLayout(
    BuildContext context,
    List<_ShellDestination> destinations,
    int safeIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: [for (final d in destinations) d.page],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(
                d.selectedIcon,
                color: d.accentColor ?? colorScheme.onSecondaryContainer,
              ),
              label: d.label,
              tooltip: d.label,
            ),
        ],
      ),
    );
  }
}
