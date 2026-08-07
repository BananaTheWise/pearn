import '../../../core/models/user.dart';

/// Abstract contract for the profile screen UI.
///
/// The view is responsible only for rendering state.
/// All business logic is handled by [ProfilePresenter].
abstract class IProfileView {
  void showLoading(bool loading);
  void showUser(User user);
  void showError(String message);
  void navigateToLogin();
}