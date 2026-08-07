import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/user.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../presenter/profile_presenter.dart';
import 'i_profile_view.dart';

/// Displays the authenticated user's profile and provides a logout option.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> implements IProfileView {
  late final ProfilePresenter _presenter;

  bool _isLoading = true;
  String? _errorMessage;
  User? _user;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][PROFILE] Profile screen opened');
    _presenter = getIt<ProfilePresenter>();
    _presenter.view = this;
    _presenter.loadProfile();
  }

  // ---------------------------------------------------------------------------
  // IProfileView implementation
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
      if (loading) _errorMessage = null;
    });
  }

  @override
  void showUser(User user) {
    debugPrint('[UI][PROFILE] Profile loaded');
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  void showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  @override
  void navigateToLogin() {
    // Replace entire navigation stack with login screen.
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _presenter.logout();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _user != null
                  ? _buildProfileContent()
                  : const Center(child: Text('No user data available.')),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _presenter.loadProfile(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = _user!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Center(
            child: SizedBox(
              width: isWide ? 600 : double.infinity,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Avatar
                  // TODO — REQUIRES ARCHITECTURE DECISION: Avatar type not in DB schema.
                  // Once a column like `avatar_type` is added to `profiles`, pass it here.
                  UserAvatar(radius: 48, avatarType: null),
                  const SizedBox(height: 16),
                  Text(
                    user.username,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  // Stats card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Level', user.currentLevel),
                          _buildStatColumn('XP', user.totalXp),
                          _buildStatColumn('Streak', user.currentStreak),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Additional profile information
                  if (user.role.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.badge),
                      title: const Text('Role'),
                      trailing: Text(_capitalize(user.role)),
                    ),
                  if (user.status.isNotEmpty)
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Status'),
                      trailing: Text(_capitalize(user.status)),
                    ),
                  if (user.lastActiveDate != null)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Last Active'),
                      trailing: Text(_formatDate(user.lastActiveDate!)),
                    ),
                  const SizedBox(height: 24),
                  // Logout button for mobile (already in AppBar but can be here too)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      onPressed: _onLogout,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}