import 'package:common_package/common_package.dart';

class OrdersLifecycleFailureMessageMapper {
  const OrdersLifecycleFailureMessageMapper._();

  static const int _statusForbidden = 403;
  static const int _statusUnprocessable = 422;
  static const int _statusTooManyRequests = 429;

  static String map(
    Failure failure, {
    required String invalidStateMessage,
  }) {
    switch (failure.statusCode) {
      case _statusForbidden:
        return 'غير مسموح بتنفيذ هذا الإجراء على الطلب.';
      case _statusTooManyRequests:
        return 'الطلبات كثيرة حالياً، حاول بعد قليل.';
      case _statusUnprocessable:
        // Preserve the backend's precise Arabic validation reason when available.
        // Otherwise use the action-specific, user-friendly fallback.
        final explanation = failure.message.trim();
        return RegExp(r'[\u0600-\u06FF]').hasMatch(explanation)
            ? explanation
            : invalidStateMessage;
      default:
        return ErrorMessageFormatter.format(failure.message);
    }
  }
}
