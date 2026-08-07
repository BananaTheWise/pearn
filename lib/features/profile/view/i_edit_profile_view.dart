import '../../../core/models/user.dart';

/// View contract for editing the user profile.
abstract class IEditProfileView {
  void showLoading(bool loading);
  void showUser(User user);           // pre-fill the form
  void showError(String message);
  void showSaved();                   // notify success
  void navigateBack();                // return to profile screen
}