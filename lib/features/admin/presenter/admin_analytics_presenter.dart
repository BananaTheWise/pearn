import 'package:flutter/foundation.dart';

import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';

/// Provides analytics data to the admin UI by fetching metrics
/// from the [AdminRepository].
///
/// Only metrics that can be derived from the existing database schema
/// are included. No statistics are invented.
class AdminAnalyticsPresenter {
  final AdminRepository _adminRepository;
  IAdminView? _view;

  AdminAnalyticsPresenter({required AdminRepository adminRepo})
      : _adminRepository = adminRepo;

  set view(IAdminView? view) {
    _view = view;
  }

  /// Retrieves system analytics and passes them to the view.
  Future<void> loadAnalytics() async {
    debugPrint('[PRESENTER][ADMIN][ANALYTICS] Loading analytics');
    _view?.showLoading(true);

    try {
      final data = await _adminRepository.getSystemAnalytics();
      _view?.showAnalytics(data);
      debugPrint('[PRESENTER][ADMIN][ANALYTICS] Analytics loaded');
    } catch (e) {
      debugPrint('[ERROR][ADMIN][ANALYTICS] Analytics load failed');
      _view?.showError('Unable to load analytics.');
    } finally {
      _view?.showLoading(false);
    }
  }
}