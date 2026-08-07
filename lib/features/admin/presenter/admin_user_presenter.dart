import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';

/// Coordinates user management operations between the admin UI
/// and the [AdminRepository].
///
/// Enforces allowed role/status transitions and logs admin actions.
class AdminUserPresenter {
  final AdminRepository _adminRepository;
  IAdminView? _view;

  // Allowed roles and statuses as per schema.
  static const List<String> allowedRoles = ['student', 'tutor', 'admin'];
  static const List<String> allowedStatuses = ['active', 'suspended', 'banned'];

  AdminUserPresenter({required AdminRepository adminRepo})
      : _adminRepository = adminRepo;

  set view(IAdminView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // loadUsers
  // ---------------------------------------------------------------------------
  Future<void> loadUsers({String? role, String? status}) async {
    debugPrint('[PRESENTER][ADMIN][USER] Loading users');
    _view?.showLoading(true);

    try {
      final users = await _adminRepository.getUsers(role: role, status: status);
      _view?.showUsers(users);
      debugPrint('[PRESENTER][ADMIN][USER] Users loaded: ${users.length}');
    } catch (e) {
      debugPrint('[ERROR][ADMIN][USER] Failed to load users');
      _view?.showError('Unable to load users.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // getUserDetails
  // ---------------------------------------------------------------------------
  Future<void> getUserDetails(String userId) async {
    debugPrint('[PRESENTER][ADMIN][USER] User details requested for $userId');
    // For simplicity, we can just navigate to a detail screen.
    // The view could have a navigateToUserDetail method – we can add it to IAdminView
    // but the current interface doesn't have it. We'll keep it as a placeholder.
    // In practice, the dashboard would handle it directly, but we'll log.
  }

  // ---------------------------------------------------------------------------
  // updateUserStatus
  // ---------------------------------------------------------------------------
  Future<void> updateUserStatus(String userId, String newStatus) async {
    debugPrint('[PRESENTER][ADMIN][USER] Status update requested: $newStatus');

    // Validate status
    if (!allowedStatuses.contains(newStatus)) {
      _view?.showError('Invalid status.');
      return;
    }

    final confirmed = await _view?.showConfirmation(
        'Change user status to $newStatus?');
    if (confirmed != true) return;

    _view?.showLoading(true);
    try {
      await _adminRepository.updateUserStatus(userId, newStatus);
      debugPrint('[AUDIT] User administrative action recorded – status changed');
      // Reload the user list to reflect changes
      await loadUsers();
    } catch (e) {
      debugPrint('[ERROR][ADMIN][USER] Status update failed');
      _view?.showError('Failed to update user status.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // updateUserRole
  // ---------------------------------------------------------------------------
  Future<void> updateUserRole(String userId, String newRole) async {
    debugPrint('[PRESENTER][ADMIN][USER] Role update requested: $newRole');

    // Validate role
    if (!allowedRoles.contains(newRole)) {
      _view?.showError('Invalid role.');
      return;
    }

    final confirmed = await _view?.showConfirmation(
        'Change user role to $newRole?');
    if (confirmed != true) return;

    _view?.showLoading(true);
    try {
      await _adminRepository.updateUserRole(userId, newRole);
      debugPrint('[AUDIT] User administrative action recorded – role changed');
      await loadUsers();
    } catch (e) {
      debugPrint('[ERROR][ADMIN][USER] Role update failed');
      _view?.showError('Failed to update role.');
    } finally {
      _view?.showLoading(false);
    }
  }
}