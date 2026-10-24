import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/data/wire_mappers.dart';

Map<String, Object?> notificationWire({
  Map<String, Object?>? data,
  String canonical = 'cleaning.booking.extension_request',
}) => {
  'id': 'notification-1',
  'title': 'Extension review',
  'body': 'A visit has a request',
  'createdAt': '2026-10-23T11:00:00+03:00',
  'readAt': null,
  'canonicalType': canonical,
  'data': data ?? <String, Object?>{},
};

void main() {
  test('S07 maps authoritative debt separately from deposit, preserving zero and unknown', () {
    Map<String, Object?> wire(Object? debt) => {
      'accountStatus': 'active',
      'financiallyEligible': true,
      'restrictionCodes': <String>[],
      'remedyDestinations': <String, String>{},
      'currentBalance': {'decimal': '400.00', 'currency': 'SYP'},
      'debtBalance': debt,
      'minimumBalance': null,
      'debtCapacity': null,
    };
    final zero = WorkerWireMappers.deposit(
        wire({'decimal': '0', 'currency': 'SYP'}));
    expect(zero.currentBalance!.decimal, '400.00');
    expect(zero.debtBalance!.decimal, '0');
    expect(zero.debtBalance!.currency, 'SYP');
    expect(WorkerWireMappers.deposit(wire(null)).debtBalance, isNull);
    expect(WorkerWireMappers.deposit(wire(null)).currentBalance!.decimal,
        '400.00');
  });

  test('S08 maps actual backend deep-link aliases and selected visit without parent fallback', () {
    final n = WorkerWireMappers.notification(notificationWire(data: {
      'deep_link_target': 'cleaning_booking_details',
      'bookingId': 123,
      'orderId': 123,
      'sessionId': 61,
      'assignmentId': 42,
      'action': 'extension_request',
      'decisionStatus': 'actionable',
      'actionable': true,
    }));
    expect(n.targetState, NotificationTargetState.ready);
    expect(n.target!.destination, WorkerDestination.mission);
    expect(n.target!.origin, RouteOrigin.notification);
    expect(n.target!.scope!.bookingId, '123');
    expect(n.target!.scope!.sessionId, '61');
    expect(n.target!.scope!.assignmentId, '42');
    expect(n.promptKind, 'extension_request');
    expect(n.promptStatus, 'actionable');
    expect(n.isRead, false);
  });

  test('S08 dispute notice opens exact ticket, not booking-level fallback', () {
    final n = WorkerWireMappers.notification(notificationWire(
      canonical: 'cleaning.booking.dispute_opened', data: {
      'deep_link_target': 'cleaning_booking_details',
      'bookingId': 60,
      'disputeId': 12,
      'action': 'dispute_opened',
    }));
    expect(n.targetState, NotificationTargetState.ready);
    expect(n.target!.destination, WorkerDestination.disputeThread);
    expect(n.target!.entityId, '12');
  });

  test('S08 refuses ambiguous or malicious selectors and never invents a target', () {
    for (final data in <Map<String, Object?>>[
      {'deep_link_target': 'https://evil.example/path', 'bookingId': 1},
      {'deep_link_target': 'cleaning_booking_details', 'bookingId': 1, 'orderId': 2},
      {'deep_link_target': 'cleaning_booking_details', 'bookingId': '../private'},
      {'deep_link_target': 'cleaning_booking_details', 'bookingId': 3,
       'sessionId': null},
      {'deep_link_target': 'cleaning_booking_details', 'actionable': false,
       'bookingId': 2},
    ]) {
      final n = WorkerWireMappers.notification(notificationWire(data: data));
      expect(n.targetState, NotificationTargetState.unavailable,
          reason: '$data');
      expect(n.target, isNull);
    }
    final withoutRoute = WorkerWireMappers.notification(notificationWire());
    expect(withoutRoute.targetState, NotificationTargetState.pending);
    expect(withoutRoute.target, isNull);
  });

  test('S08 never infers prompt decision authority from status or legacy action', () {
    final base = {'deep_link_target': 'cleaning_booking_details',
                  'bookingId': 123, 'action': 'extension_request'};
    final legacy = WorkerWireMappers.notification(notificationWire(data: base));
    expect(legacy.promptKind, 'extension_request');
    expect(legacy.promptStatus, isNull);
    final pending = WorkerWireMappers.notification(notificationWire(data: {
      ...base, 'decisionStatus': 'actionable',
    }));
    expect(pending.promptStatus, isNull);
    final completed = WorkerWireMappers.notification(notificationWire(data: {
      ...base, 'decisionStatus': 'handled', 'actionable': true,
    }));
    expect(completed.promptStatus, 'handled');
    expect(completed.targetState, NotificationTargetState.ready);
  });

  test('S08 preserves backend Laravel paginator and retains unavailable rows', () {
    final page = WorkerWireMappers.notificationPage({
      'data': [
        notificationWire(data: {
          'state': 'unavailable',
          'actionable': false,
          'deep_link_target': 'cleaning_booking_details',
          'bookingId': 500,
        }),
        notificationWire(data: {
          'deep_link_target': 'cleaning_booking_details',
          'bookingId': 501,
          'sessionId': 22,
        }),
      ],
      'meta': {'current_page': 2, 'last_page': 4, 'total': 37},
    });
    expect(page.page, 2);
    expect(page.lastPage, 4);
    expect(page.total, 37);
    expect(page.items, hasLength(2));
    expect(page.items.first.target, isNull);
    expect(page.items.first.targetState, NotificationTargetState.unavailable);
    expect(page.items.last.target!.scope!.sessionId, '22');
  });
}
