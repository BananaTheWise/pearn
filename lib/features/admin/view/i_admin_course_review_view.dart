// lib/features/admin/view/i_admin_course_review_view.dart
abstract class IAdminCourseReviewView {
  void showLoading(bool loading);
  void showPendingCourses(List<Map<String, dynamic>> courses);
  void showError(String message);
  void showApprovalSuccess(String courseId);
  void showRejectionSuccess(String courseId);
}