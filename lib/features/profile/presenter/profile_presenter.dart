import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../../auth/model/auth_service.dart';
import '../../auth/model/user_repository.dart';
import '../view/i_profile_view.dart';

/// Coordinates profile screen UI with user data and authentication.
class ProfilePresenter {
  final UserRepository _userRepository;
  final AuthService _authService;
  final String _userId;

  IProfileView? _view;

  ProfilePresenter({
    required UserRepository userRepository,
    required AuthService authService,
    required String userId,
  })  : _userRepository = userRepository,
        _authService = authService,
        _userId = userId;

  set view(IProfileView? view) {
    _view = view;
  }

  /// Loads the user profile and passes it to the view.
  Future<void> loadProfile() async {
    debugPrint('[PRESENTER][PROFILE] Loading profile');
    _view?.showLoading(true);

    try {
      final user = await _userRepository.findById(_userId);
      if (user == null) {
        _view?.showError('User profile not found.');
        return;
      }
      _view?.showUser(user);
      debugPrint('[PRESENTER][PROFILE] Profile loaded');
    } catch (e) {
      debugPrint('[PRESENTER][PROFILE] Failed to load profile');
      _view?.showError('Unable to load profile. Please try again.');
    } finally {
      _view?.showLoading(false);
    }
  }

  /// Logs the user out and navigates to the login screen.
  Future<void> logout() async {
    debugPrint('[PRESENTER][PROFILE] Logout initiated');
    try {
      await _authService.logout();
      _view?.navigateToLogin();
    } catch (e) {
      debugPrint('[PRESENTER][PROFILE] Logout failed');
      _view?.showError('Logout failed. Please try again.');
    }
  }
}