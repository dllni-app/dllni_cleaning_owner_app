import 'common.dart';

enum WorkerDestination {
  today('today'),
  jobs('jobs'),
  schedule('schedule'),
  earnings('earnings'),
  account('account'),
  login('login'),
  readiness('readiness'),
  offer('offer'),
  mission('mission'),
  visitScope('visit_scope'),
  earningDetail('earning_detail'),
  depositAccount('deposit_account'),
  depositLedger('deposit_ledger'),
  disputes('disputes'),
  disputeThread('dispute_thread'),
  notifications('notifications'),
  support('support'),
  sos('sos'),
  profileEdit('profile_edit'),
  workAreas('work_areas'),
  workingHours('working_hours'),
  startLocation('start_location'),
  reviews('reviews'),
  language('language'),
  privacy('privacy'),
  terms('terms');

  const WorkerDestination(this.id);
  final String id;

  static WorkerDestination? byId(String id) {
    for (final destination in values) {
      if (destination.id == id) return destination;
    }
    return null;
  }
}

enum RouteOrigin {
  today,
  jobs,
  schedule,
  notification,
  profile,
  mission,
  finance,
  system,
}

enum WorkerTab {
  today(0, WorkerDestination.today),
  jobs(1, WorkerDestination.jobs),
  schedule(2, WorkerDestination.schedule),
  earnings(3, WorkerDestination.earnings),
  account(4, WorkerDestination.account);

  const WorkerTab(this.tabIndex, this.destination);
  final int tabIndex;
  final WorkerDestination destination;
}

/// Legacy MainScreen indexes 0 Today, 1 Schedule, 2 Jobs, 3 Profile.
WorkerTab? tabFromLegacyIndex(int value) => switch (value) {
  0 => WorkerTab.today,
  1 => WorkerTab.schedule,
  2 => WorkerTab.jobs,
  3 => WorkerTab.account,
  _ => null,
};

class RouteIntent {
  RouteIntent({
    required this.destination,
    required this.origin,
    this.scope,
    this.jobsStatusFilter,
    String? entityId,
  }) : entityId = entityId == null ? null : requireId(entityId, 'entityId') {
    validate();
  }

  final WorkerDestination destination;
  final RouteOrigin origin;
  final WorkScope? scope;

  /// Typed tab filter carried from the old MainScreen orders status request.
  final String? jobsStatusFilter;
  final String? entityId;

  void validate() {
    switch (destination) {
      case WorkerDestination.mission:
      case WorkerDestination.visitScope:
      case WorkerDestination.sos:
      case WorkerDestination.offer:
        if (scope == null) {
          throw ArgumentError('Destination requires booking scope');
        }
      case WorkerDestination.earningDetail:
      case WorkerDestination.disputeThread:
        if (entityId == null) {
          throw ArgumentError('Destination requires entity ID');
        }
        if (destination == WorkerDestination.earningDetail &&
            !RegExp(
              r'^(session_assignment|booking_assignment|legacy_booking):[^:]+$',
            ).hasMatch(entityId!)) {
          throw ArgumentError(
            'Earning detail requires source-qualified entry key',
          );
        }
      default:
        break;
    }
  }
}

class RouteResolution {
  const RouteResolution._(this.intent, this.errorCode);
  const RouteResolution.available(RouteIntent route) : this._(route, null);
  const RouteResolution.unavailable(String reason) : this._(null, reason);
  final RouteIntent? intent;

  /// Localizable error; never exposes server implementation details.
  final String? errorCode;
  bool get isAvailable => intent != null;
}

/// Compatibility translation only; S00 still authorizes actor and visit
/// membership before rendering the target. Neither target nor session is
/// silently substituted when a selected visit has become unavailable.
class LegacyRouteAdapter {
  const LegacyRouteAdapter._();

  static RouteResolution resolve(
    String routeName,
    Object? arguments, {
    RouteOrigin origin = RouteOrigin.system,
  }) {
    try {
      final map = arguments is Map ? arguments : <Object?, Object?>{};
      final booking = _identity(map, const [
        'bookingId',
        'booking_id',
        'orderId',
        'order_id',
      ]);
      final session = _identity(map, const [
        'sessionId',
        'session_id',
        'cleaningBookingSessionId',
        'cleaning_booking_session_id',
      ]);
      final assignment = _identity(map, const [
        'assignmentId',
        'assignment_id',
      ]);
      if (!booking.valid ||
          !session.valid ||
          !assignment.valid ||
          ((session.present || assignment.present) && !booking.present) ||
          (booking.present && session.present && session.value == null) ||
          (booking.present && assignment.present && assignment.value == null)) {
        return const RouteResolution.unavailable('target_invalid');
      }
      final scope = !booking.present
          ? null
          : WorkScope(
              bookingId: booking.value!,
              sessionId: session.value,
              assignmentId: assignment.value,
            );
      final dispute = _identity(map, const ['disputeId', 'dispute_id', 'id']);
      final earning = _identity(map, const ['entryKey', 'entry_key']);
      final genericId = _identity(map, const ['id']);
      final destination = switch (routeName) {
        '/login' => WorkerDestination.login,
        '/main' => WorkerDestination.today,
        '/orderdetails' ||
        'cleaning_booking_details' => WorkerDestination.mission,
        '/emergencysos' => WorkerDestination.sos,
        '/transactiondetails' => WorkerDestination.disputeThread,
        '/transactionhistory' => WorkerDestination.depositLedger,
        '/notifications' => WorkerDestination.notifications,
        '/profile' => WorkerDestination.account,
        '/editprofile' || '/updateprofile' => WorkerDestination.profileEdit,
        '/workareas' => WorkerDestination.workAreas,
        '/workinghours' || '/workingtime' => WorkerDestination.workingHours,
        '/reviews' || '/workerreviews' => WorkerDestination.reviews,
        '/startlocation' => WorkerDestination.startLocation,
        _ => WorkerDestination.byId(routeName),
      };
      if (destination == null) {
        return const RouteResolution.unavailable('target_unknown');
      }
      if (!dispute.valid || !earning.valid || !genericId.valid) {
        return const RouteResolution.unavailable('target_invalid');
      }
      final entityId = switch (destination) {
        WorkerDestination.disputeThread => dispute.value,
        WorkerDestination.earningDetail => earning.value,
        _ => genericId.value,
      };
      return RouteResolution.available(
        RouteIntent(
          destination: destination,
          origin: origin,
          scope: scope,
          entityId: entityId,
        ),
      );
    } on ArgumentError {
      return const RouteResolution.unavailable('target_invalid');
    }
  }

  static _RouteIdentity _identity(
    Map<dynamic, dynamic> map,
    List<String> aliases,
  ) {
    final presentValues = <String?>[];
    for (final alias in aliases) {
      if (!map.containsKey(alias)) continue;
      final raw = map[alias];
      if (raw is int && raw > 0) {
        presentValues.add('$raw');
      } else if (raw is String && raw.trim().isNotEmpty) {
        presentValues.add(raw.trim());
      } else {
        presentValues.add(null);
      }
    }
    if (presentValues.isEmpty) return const _RouteIdentity.absent();
    final first = presentValues.first;
    final consistent = first != null && presentValues.every((v) => v == first);
    return _RouteIdentity(true, consistent, consistent ? first : null);
  }
}

class _RouteIdentity {
  const _RouteIdentity(this.present, this.valid, this.value);
  const _RouteIdentity.absent() : this(false, true, null);
  final bool present;
  final bool valid;
  final String? value;
}
