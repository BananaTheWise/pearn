import 'package:flutter/foundation.dart';

import '../../../core/services/connectivity_service.dart';
import '../model/admin_repository.dart';
import '../view/i_admin_view.dart';

/// Coordinates system-level operations for the admin UI.
///
/// Provides a combined view of backend health (via repository analytics) and
/// device connectivity status.  Other system features (sync status,
/// configuration) can be added when the corresponding services exist.
class AdminSystemPresenter {
  final AdminRepository _adminRepository;
  final ConnectivityService _connectivityService;
  IAdminView? _view;

  AdminSystemPresenter({
    required AdminRepository adminRepository,
    required ConnectivityService connectivityService,
  })  : _adminRepository = adminRepository,
        _connectivityService = connectivityService;

  set view(IAdminView? view) {
    _view = view;
  }

  /// Loads system status information and passes it to the view.
  Future<void> loadSystemStatus() async {
    debugPrint('[PRESENTER][ADMIN][SYSTEM] Loading system status');
    _view?.showLoading(true);

    try {
      // Gather connectivity status
      final isOnline = await _connectivityService.isOnline();

      // Gather backend analytics (proves DB is reachable)
      Map<String, dynamic> analytics;
      try {
        analytics = await _adminRepository.getSystemAnalytics();
      } catch (e) {
        // Backend might be down
        analytics = {'error': 'Failed to reach backend'};
      }

      final status = {
        'online': isOnline,
        'analytics': analytics,
        // Sync status and other configuration could be added later
      };

      _view?.showSystemStatus(status);
      debugPrint('[PRESENTER][ADMIN][SYSTEM] System status loaded');
    } catch (e) {
      debugPrint('[ERROR][ADMIN][SYSTEM] System status failed');
      _view?.showError('Unable to load system status.');
    } finally {
      _view?.showLoading(false);
    }
  }
}