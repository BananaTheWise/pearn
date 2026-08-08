import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../presenter/settings_presenter.dart';
import 'i_settings_view.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> implements ISettingsView {
  late final SettingsPresenter _presenter;
  bool _isLoading = false;
  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][SETTINGS] Settings opened');
    _presenter = getIt<SettingsPresenter>();
    _presenter.view = this;
    _presenter.loadSettings();
  }

  // ---------------------------------------------------------------------------
  // ISettingsView
  // ---------------------------------------------------------------------------

  @override
  void showLoading(bool loading) {
    setState(() {
      _isLoading = loading;
    });
  }

  @override
  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  void updateThemeMode(ThemeMode mode) {
    setState(() {
      _currentThemeMode = mode;
    });
  }

  // ---------------------------------------------------------------------------
  // Theme toggle
  // ---------------------------------------------------------------------------
  void _onThemeChanged(ThemeMode? mode) {
    if (mode != null) {
      _presenter.setThemeMode(mode);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
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
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme section
          const _SectionHeader(title: 'Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('System Default'),
            value: ThemeMode.system,
            groupValue: _currentThemeMode,
            onChanged: _isLoading ? null : _onThemeChanged,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light'),
            value: ThemeMode.light,
            groupValue: _currentThemeMode,
            onChanged: _isLoading ? null : _onThemeChanged,
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark'),
            value: ThemeMode.dark,
            groupValue: _currentThemeMode,
            onChanged: _isLoading ? null : _onThemeChanged,
          ),
          const Divider(),

          // Profile
          const _SectionHeader(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/edit-profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Create Course'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/create-course'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _isLoading ? null : _onLogout,
          ),
          const Divider(),

          // About / policies
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _isLoading
                ? null
                : () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
    );
  }
}

/// Simple helper for section titles inside a ListView.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}