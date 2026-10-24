import 'package:flutter/material.dart';

import '../notifications/cleaning_notification_order_loader_screen.dart';
import '../../generated/app_routes.g.dart';
import '../../presentation/worker_v2/contracts/common.dart';
import '../../presentation/worker_v2/contracts/navigation.dart';
import '../../features/orders/view/screens/order_details_screen.dart';
import '../../features/orders/view/screens/emergency_sos_screen.dart';
import '../../features/profile/view/screens/transaction_details_screen.dart';
import '../../features/main/view/screens/main_screen.dart';

class AppRouter {
  const AppRouter._();

  /// S00 migration seam: translate *actual* legacy param objects to pure IDs.
  /// Used for compatibility tests until the reviewed new modules are composed.
  /// Does not change the existing application's production route handlers.
  static RouteResolution previewWorkerRebuildIntent(
    RouteSettings settings, {
    RouteOrigin origin = RouteOrigin.system,
  }) {
    final args = settings.arguments;
    final route = settings.name;
    if (route == null) {
      return const RouteResolution.unavailable('target_unknown');
    }
    if (args is OrderDetailsScreenParams && route == '/orderdetails') {
      final id = args.order.id;
      if (id == null ||
          id <= 0 ||
          (args.selectedSessionId != null && args.selectedSessionId! <= 0)) {
        return const RouteResolution.unavailable('target_invalid');
      }
      return RouteResolution.available(
        RouteIntent(
          destination: WorkerDestination.mission,
          origin: origin,
          scope: WorkScope(
            bookingId: '$id',
            sessionId: args.selectedSessionId?.toString(),
          ),
        ),
      );
    }
    if (args is EmergencySosScreenParams && route == '/emergencysos') {
      if (args.bookingId <= 0) {
        return const RouteResolution.unavailable('target_invalid');
      }
      return RouteResolution.available(
        RouteIntent(
          destination: WorkerDestination.sos,
          origin: origin,
          scope: WorkScope(bookingId: '${args.bookingId}'),
        ),
      );
    }
    if (args is TransactionDetailsScreenParam &&
        route == '/transactiondetails') {
      if (args.id <= 0) {
        return const RouteResolution.unavailable('target_invalid');
      }
      return RouteResolution.available(
        RouteIntent(
          destination: WorkerDestination.disputeThread,
          origin: origin,
          entityId: '${args.id}',
        ),
      );
    }
    if (args is MainScreenParam && route == '/main') {
      final tab = tabFromLegacyIndex(args.returnedPageIndex);
      if (tab == null) {
        return const RouteResolution.unavailable('target_invalid');
      }
      return RouteResolution.available(
        RouteIntent(
          destination: tab.destination,
          origin: origin,
          jobsStatusFilter: args.ordersInitialStatus,
        ),
      );
    }
    return LegacyRouteAdapter.resolve(route, args, origin: origin);
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == 'cleaning_booking_details') {
      final bookingId = _bookingId(settings.arguments);
      final selectedSession = _selectedSessionId(settings.arguments);
      if (bookingId == null || !selectedSession.valid) {
        return _errorRoute(settings);
      }

      return MaterialPageRoute(
        builder: (_) => CleaningNotificationOrderLoaderScreen(
          bookingId: bookingId,
          selectedSessionId: selectedSession.id,
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

    int? bookingId;
    for (final key in const [
      'bookingId',
      'booking_id',
      'orderId',
      'order_id',
    ]) {
      if (!arguments.containsKey(key)) continue;
      final value = arguments[key];
      // A legacy notification may contain multiple aliases. Reject conflicting
      // or malformed values rather than opening the wrong customer's booking.
      final parsed = _positiveInteger(value);
      if (parsed == null) return null;
      if (bookingId != null && bookingId != parsed) return null;
      bookingId = parsed;
    }

    return bookingId;
  }

  static ({int? id, bool valid}) _selectedSessionId(Object? arguments) {
    if (arguments is! Map) return (id: null, valid: true);
    int? selectedId;
    for (final key in const [
      'sessionId',
      'session_id',
      'cleaningBookingSessionId',
      'cleaning_booking_session_id',
    ]) {
      if (!arguments.containsKey(key)) continue;
      final parsed = _positiveInteger(arguments[key]);
      if (parsed == null || (selectedId != null && parsed != selectedId)) {
        return (id: null, valid: false);
      }
      selectedId = parsed;
    }
    return (id: selectedId, valid: true);
  }

  static int? _positiveInteger(Object? value) {
    final parsed = value is int
        ? value
        : value is num && value.isFinite && value == value.truncateToDouble()
        ? value.toInt()
        : value is String
        ? int.tryParse(value.trim())
        : null;
    return parsed != null && parsed > 0 ? parsed : null;
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
