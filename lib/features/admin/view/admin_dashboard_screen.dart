import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/user.dart';
import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';
import 'admin_dashboard_presenter.dart'; // defined below

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

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][ADMIN] Admin dashboard opened');
    _presenter = getIt<AdminDashboardPresenter>();
    _presenter.view = this;
    _presenter.verifyAdminAccess(); // will load initial data or redirect
  }

  // ---------------------------------------------------------------------------
  // IAdminView implementation
  // ---------------------------------------------------------------------------
  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showUsers(List<User> users) {
    setState(() {
      _users = users;
    });
  }

  @override
  void showTutors(List<User> tutors) {
    setState(() {
      _tutors = tutors;
    });
  }

  @override
  void showPendingCourses(List<Map<String, dynamic>> courses) {
    setState(() {
      _pendingCourses = courses;
    });
  }

  @override
  void showReports(List<Map<String, dynamic>> reports) {
    setState(() {
      _reports = reports;
    });
  }

  @override
  void showAnalytics(Map<String, dynamic> data) {
    setState(() {
      _analytics = data;
    });
  }

  @override
  void showSystemStatus(Map<String, dynamic> status) {
    setState(() {
      _systemStatus = status;
    });
  }

  @override
  Future<bool> showConfirmation(String message) async {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildTabContent(),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
                BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
                BottomNavigationBarItem(icon: Icon(Icons.person_search), label: 'Tutors'),
                BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
              ],
            ),
      drawer: isWide
          ? null
          : Drawer(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('Analytics'),
                    selected: _currentTabIndex == 0,
                    onTap: () { _onTabTapped(0); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.school),
                    title: const Text('Courses'),
                    selected: _currentTabIndex == 1,
                    onTap: () { _onTabTapped(1); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Users'),
                    selected: _currentTabIndex == 2,
                    onTap: () { _onTabTapped(2); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_search),
                    title: const Text('Tutors'),
                    selected: _currentTabIndex == 3,
                    onTap: () { _onTabTapped(3); Navigator.pop(context); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.report),
                    title: const Text('Reports'),
                    selected: _currentTabIndex == 4,
                    onTap: () { _onTabTapped(4); Navigator.pop(context); },
                  ),
                ],
              ),
            ),
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