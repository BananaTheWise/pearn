import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../../auth/model/user_repository.dart';
import '../view/i_edit_profile_view.dart';

/// Coordinates profile editing UI with the user repository.
///
/// The only field editable by the user is [username]. All other fields
/// are system-managed and must not be modified here.
class EditProfilePresenter {
  final UserRepository _userRepository;
  final String _userId;

  IEditProfileView? _view;
  User? _currentUser;

  EditProfilePresenter({
    required UserRepository userRepository,
    required String userId,
  })  : _userRepository = userRepository,
        _userId = userId;

  set view(IEditProfileView? view) {
    _view = view;
  }

  /// Loads the user profile to pre-populate the form.
  Future<void> loadProfile() async {
    debugPrint('[PRESENTER][PROFILE] Loading profile for editing');
    _view?.showLoading(true);

    try {
      _currentUser = await _userRepository.findById(_userId);
      if (_currentUser == null) {
        _view?.showError('User profile not found.');
        return;
      }
      _view?.showUser(_currentUser!);
    } catch (e) {
      debugPrint('[PRESENTER][PROFILE] Failed to load profile for edit');
      _view?.showError('Unable to load profile. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  /// Saves the updated username.
  ///
  /// [newUsername] must not be empty and may be trimmed.
  Future<void> saveProfile(String newUsername) async {
    if (_currentUser == null) return;

    final trimmed = newUsername.trim();
    if (trimmed.isEmpty) {
      _view?.showError('Username cannot be empty.');
      return;
    }

    debugPrint('[PRESENTER][PROFILE] Saving profile');
    _view?.showLoading(true);

    try {
      final updatedUser = _currentUser!.copyWith(username: trimmed);
      await _userRepository.save(updatedUser);
      debugPrint('[PRESENTER][PROFILE] Profile saved');
      _view?.showSaved();
      // Optionally navigate back after a short delay so the user sees the success message
      Future.delayed(const Duration(seconds: 1), _view?.navigateBack);
    } catch (e) {
      debugPrint('[PRESENTER][PROFILE] Failed to save profile');
      _view?.showError('Could not save profile. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }
}