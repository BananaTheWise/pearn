import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/user.dart';
import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';
import '../presenter/admin_dashboard_presenter.dart'; // defined below

/// Main Admin control panel.
///
/// Provides access to user management, course review, analytics, and reports.
/// Access is only granted to users with the 'admin' role.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    implements IAdminView {
  late final AdminDashboardPresenter _presenter;
  int _currentTabIndex = 0;

  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  List<User> _users = [];
  List<User> _tutors = [];
  List<Map<String, dynamic>> _pendingCourses = [];
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _systemStatus = {};

  static const List<_AdminTab> _tabs = [
    _AdminTab(icon: Icons.analytics, label: 'Analytics'),
    _AdminTab(icon: Icons.school, label: 'Courses'),
    _AdminTab(icon: Icons.people, label: 'Users'),
    _AdminTab(icon: Icons.person_search, label: 'Tutors'),
    _AdminTab(icon: Icons.report, label: 'Reports'),
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][ADMIN] Admin dashboard opened');
    _presenter = getIt<AdminDashboardPresenter>();
    _presenter.view = this;
    _presenter.verifyAdminAccess(); // will load initial data or redirect
  }

  @override
  void dispose() {
    // CRITICAL: without this, the presenter keeps a live reference to this
    // State object. If it outlives the widget (e.g. the shell swaps tabs or
    // the user signs out while a request is in flight), any pending
    // callback will call setState()/ScaffoldMessenger on a deactivated
    // widget and throw "Looking up a deactivated widget's ancestor is
    // unsafe" — which then corrupts the current frame and cascades into
    // render-layer assertion failures on every subsequent frame.
    debugPrint('[UI][ADMIN] Admin dashboard disposed');
    _presenter.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IAdminView implementation
  //
  // Every method here is a callback the presenter can fire *after* an await
  // completes, at which point this State may no longer be mounted even if
  // dispose() above hasn't run yet (there's an unavoidable race between the
  // await resolving and the dispose call landing). `mounted` guards make
  // each callback a no-op instead of a crash in that window.
  // ---------------------------------------------------------------------------
  @override
  void showLoading(bool loading) {
    if (!mounted) return;
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showUsers(List<User> users) {
    if (!mounted) return;
    setState(() {
      _users = users;
    });
  }

  @override
  void showTutors(List<User> tutors) {
    if (!mounted) return;
    setState(() {
      _tutors = tutors;
    });
  }

  @override
  void showPendingCourses(List<Map<String, dynamic>> courses) {
    if (!mounted) return;
    setState(() {
      _pendingCourses = courses;
    });
  }

  @override
  void showReports(List<Map<String, dynamic>> reports) {
    if (!mounted) return;
    setState(() {
      _reports = reports;
    });
  }

  @override
  void showAnalytics(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      _analytics = data;
    });
  }

  @override
  void showSystemStatus(Map<String, dynamic> status) {
    if (!mounted) return;
    setState(() {
      _systemStatus = status;
    });
  }

  @override
  Future<bool> showConfirmation(String message) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab navigation
  // ---------------------------------------------------------------------------
  void _onTabTapped(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    // Load data for selected tab if needed
    switch (index) {
      case 0: _presenter.loadAnalytics(); break;
      case 1: _presenter.loadPendingCourses(); break;
      case 2: _presenter.loadUsers(); break;
      case 3: _presenter.loadTutors(); break;
      case 4: _presenter.loadReports(); break;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: isWide
          ? Row(
              children: [
                _buildNavigationRail(),
                const VerticalDivider(width: 1),
                Expanded(child: _buildBody()),
              ],
            )
          : _buildBody(),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              items: _tabs
                  .map((tab) => BottomNavigationBarItem(
                        icon: Icon(tab.icon),
                        label: tab.label,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildBody() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _buildTabContent();
  }

  /// Persistent side navigation shown on wide screens instead of the
  /// bottom nav bar, so tabs remain switchable when width > 600.
  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _currentTabIndex,
      onDestinationSelected: _onTabTapped,
      labelType: NavigationRailLabelType.all,
      destinations: _tabs
          .map((tab) => NavigationRailDestination(
                icon: Icon(tab.icon),
                label: Text(tab.label),
              ))
          .toList(),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0: return _buildAnalyticsSection();
      case 1: return _buildCoursesSection();
      case 2: return _buildUsersSection();
      case 3: return _buildTutorsSection();
      case 4: return _buildReportsSection();
      default: return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // Section widgets
  // ---------------------------------------------------------------------------
  Widget _buildAnalyticsSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('System Analytics', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        _buildStatCard('Total Users', _analytics['total_users']?.toString() ?? '-'),
        _buildStatCard('Active Users', _analytics['active_users']?.toString() ?? '-'),
        _buildStatCard('Total Courses', _analytics['total_courses']?.toString() ?? '-'),
        _buildStatCard('Total Enrollments', _analytics['total_enrollments']?.toString() ?? '-'),
      ],
    );
  }

  Widget _buildCoursesSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pending Courses', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_pendingCourses.isEmpty)
          const Text('No pending courses.')
        else
          ..._pendingCourses.map((course) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(course['title'] ?? 'Untitled'),
                  subtitle: Text('Tutor: ${course['tutor_id'] ?? 'Unknown'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _presenter.approveCourse(course['id']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _presenter.rejectCourse(course['id']),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildUsersSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Users', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_users.isEmpty)
          const Text('No users found.')
        else
          ..._users.map((user) => ListTile(
                title: Text(user.username),
                subtitle: Text('${user.role} • ${user.status}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'suspend') _presenter.updateUserStatus(user.id, 'suspended');
                    else if (action == 'activate') _presenter.updateUserStatus(user.id, 'active');
                    else if (action == 'ban') _presenter.updateUserStatus(user.id, 'banned');
                    else if (action == 'promote') _presenter.updateUserRole(user.id, 'admin');
                    else if (action == 'demote') _presenter.updateUserRole(user.id, 'student');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                    const PopupMenuItem(value: 'activate', child: Text('Activate')),
                    const PopupMenuItem(value: 'ban', child: Text('Ban')),
                    const PopupMenuItem(value: 'promote', child: Text('Make Admin')),
                    const PopupMenuItem(value: 'demote', child: Text('Demote to Student')),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildTutorsSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tutors', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_tutors.isEmpty)
          const Text('No tutors found.')
        else
          ..._tutors.map((tutor) => ListTile(
                title: Text(tutor.username),
                subtitle: Text('Status: ${tutor.status}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'suspend') _presenter.updateTutorStatus(tutor.id, 'suspended');
                    else if (action == 'activate') _presenter.updateTutorStatus(tutor.id, 'active');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                    const PopupMenuItem(value: 'activate', child: Text('Activate')),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildReportsSection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        if (_reports.isEmpty)
          const Text('No unresolved reports.')
        else
          ..._reports.map((report) => ListTile(
                title: Text('Report #${report['id']}'),
                subtitle: Text('Reason: ${report['reason'] ?? 'N/A'}'),
                trailing: ElevatedButton(
                  onPressed: () => _presenter.resolveReport(report['id']),
                  child: const Text('Resolve'),
                ),
              )),
      ],
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Simple value object describing one admin dashboard tab.
class _AdminTab {
  final IconData icon;
  final String label;

  const _AdminTab({required this.icon, required this.label});
}