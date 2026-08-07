import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/di.dart';
import '../../../core/models/user.dart';
import '../presenter/edit_profile_presenter.dart';
import 'i_edit_profile_view.dart';

/// Allows the user to edit their profile (currently only the username).
///
/// Fields that do not exist in the database schema (like avatar) are not
/// shown.  Only mutable fields are presented.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    implements IEditProfileView {
  late final EditProfilePresenter _presenter;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[UI][PROFILE] Edit profile opened');
    _presenter = getIt<EditProfilePresenter>();
    _presenter.view = this;
    _presenter.loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // IEditProfileView
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
    _usernameController.text = user.username;
    setState(() {
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
  void showSaved() {
    setState(() {
      _isSaved = true;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated')),
    );
  }

  @override
  void navigateBack() {
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      await _presenter.saveProfile(_usernameController.text);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _onSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildForm(),
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

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Public information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Note: No role / status editing for regular users.
            // Only fields present in the schema and user-mutable are shown.
            if (_isSaved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Profile saved.',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}