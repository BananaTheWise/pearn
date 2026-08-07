import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';

/// Coordinates tutor management between the admin UI and the [AdminRepository].
///
/// Only users with the admin role may execute these operations.
class AdminTutorPresenter {
  final AdminRepository _adminRepository;
  IAdminView? _view;

  AdminTutorPresenter({required AdminRepository adminRepo})
      : _adminRepository = adminRepo;

  set view(IAdminView? view) {
    _view = view;
  }

  // ---------------------------------------------------------------------------
  // loadTutors
  // ---------------------------------------------------------------------------
  Future<void> loadTutors() async {
    debugPrint('[PRESENTER][ADMIN][TUTOR] Loading tutors');
    _view?.showLoading(true);

    try {
      final tutors = await _adminRepository.getTutors();
      _view?.showTutors(tutors);
      debugPrint('[PRESENTER][ADMIN][TUTOR] Tutors loaded: ${tutors.length}');
    } catch (e) {
      debugPrint('[ERROR][ADMIN][TUTOR] Failed to load tutors');
      _view?.showError('Unable to load tutors.');
    } finally {
      _view?.showLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // getTutorDetails
  // ---------------------------------------------------------------------------
  Future<User?> getTutorDetails(String tutorId) async {
    debugPrint('[PRESENTER][ADMIN][TUTOR] Tutor details requested: $tutorId');
    try {
      final tutor = await _adminRepository.getTutor(tutorId);
      if (tutor == null) {
        _view?.showError('Tutor not found.');
      }
      // Note: The current IAdminView does not have a method to display a single
      // tutor in detail. In a full implementation, the presenter would call
      // something like `_view.showTutorDetail(tutor)`.
      return tutor;
    } catch (e) {
      debugPrint('[ERROR][ADMIN][TUTOR] Failed to get tutor details');
      _view?.showError('Unable to load tutor details.');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // updateTutorStatus
  // ---------------------------------------------------------------------------
  Future<void> updateTutorStatus(String tutorId, String newStatus) async {
    debugPrint('[PRESENTER][ADMIN][TUTOR] Tutor status update requested: $newStatus');

    // Validate status against allowed values (same as user)
    if (!['active', 'suspended', 'banned'].contains(newStatus)) {
      _view?.showError('Invalid status.');
      return;
    }

    final confirmed = await _view?.showConfirmation(
        'Change tutor status to $newStatus?');
    if (confirmed != true) return;

    _view?.showLoading(true);
    try {
      await _adminRepository.updateTutorStatus(tutorId, newStatus);
      debugPrint('[AUDIT] Tutor administrative action recorded');
      await loadTutors(); // refresh list
    } catch (e) {
      debugPrint('[ERROR][ADMIN][TUTOR] Status update failed');
      _view?.showError('Failed to update tutor status.');
    } finally {
      _view?.showLoading(false);
    }
  }
}