import 'package:flutter/material.dart';

import '../notifications/cleaning_notification_order_loader_screen.dart';
import '../../generated/app_routes.g.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == 'cleaning_booking_details') {
      final bookingId = _bookingId(settings.arguments);
      if (bookingId == null) {
        return _errorRoute(settings);
      }

      return MaterialPageRoute(
        builder: (_) => CleaningNotificationOrderLoaderScreen(
          bookingId: bookingId,
        ),
        settings: settings,
      );
    }

    return GeneratedAppRoutes.onGenerateRoute(settings);
  }

  static int? _bookingId(Object? arguments) {
    if (arguments is! Map) {
      return null;
    }

    for (final key in const ['bookingId', 'booking_id', 'orderId', 'order_id']) {
      final value = arguments[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Unable to open cleaning booking')),
      ),
      settings: settings,
    );
  }
}
