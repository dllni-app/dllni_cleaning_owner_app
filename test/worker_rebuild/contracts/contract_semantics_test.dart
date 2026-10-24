import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/fixtures/base_fixtures.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/navigation.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/requests.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/tooling/check_boundaries.dart'
    as boundaries;

void main() {
  test('scope preserves the selected visit and rejects blank identity', () {
    final scope = WorkScope(bookingId: '7', sessionId: '12', assignmentId: '9');
    expect(scope.bookingId, '7');
    expect(scope.sessionId, '12');
    expect(scope.cacheKey, '["7","12","9"]');
    expect(
      WorkScope(bookingId: 'a:b', sessionId: 'c').cacheKey,
      isNot(WorkScope(bookingId: 'a', sessionId: 'b:c').cacheKey),
    );
    expect(() => WorkScope(bookingId: ' '), throwsArgumentError);
    expect(() => WorkScope(bookingId: '1', sessionId: ''), throwsArgumentError);
  });

  test('valid zero is distinct from unallocated finance entry', () {
    final zero = MoneyValue(decimal: '0.00', currency: 'SYP');
    expect(zero.decimal, '0.00');
    expect(
      () => MoneyValue(decimal: '1,000.00', currency: 'SYP'),
      throwsArgumentError,
    );
    expect(
      () => MoneyValue(decimal: '1e5', currency: 'SYP'),
      throwsArgumentError,
    );
    expect(
      () => MoneyValue(decimal: '1', currency: 'syp'),
      throwsArgumentError,
    );
    expect(
      BaseFixtures.scenarios
          .singleWhere((f) => f.code == 'missing_allocation')
          .earning!
          .authoritativeAmount,
      isNull,
    );
    expect(
      BaseFixtures.scenarios
          .singleWhere((f) => f.code == 'valid_zero_money')
          .money!
          .decimal,
      '0.00',
    );
  });

  test(
    'supervisor execution blocked while personal attendance remains independent',
    () {
      final fixture = BaseFixtures.scenarios.singleWhere(
        (f) => f.code == 'standard_kind_supervisor_v2',
      );
      expect(fixture.operational.executionOwner, ExecutionOwner.supervisor);
      expect(fixture.operational.executionCapability, false);
      expect(fixture.operational.canRecordAttendance, true);
      expect(fixture.operational.permits(WorkerAction.confirmWorkStart), false);
      final conflicting = OperationalContext(
        executionOwner: ExecutionOwner.supervisor,
        executionCapability: false,
        allowedActions: {
          WorkerAction.confirmWorkStart,
          WorkerAction.arrive,
          WorkerAction.sendSos,
        },
        canRecordAttendance: true,
      );
      expect(conflicting.permits(WorkerAction.confirmWorkStart), false);
      expect(conflicting.permits(WorkerAction.arrive), true);
      expect(conflicting.permits(WorkerAction.sendSos), true);
      expect(
        () => OperationalContext(
          executionOwner: null,
          executionCapability: false,
          allowedActions: {},
          blockedReasons: {'internal_supervisor_rate'},
          canRecordAttendance: false,
        ),
        throwsArgumentError,
      );
      expect(WorkerAction.fromWire('unknown_action'), isNull);
    },
  );

  test('server result cardinality and read/command outcomes are distinct', () {
    final page = Page<int>(items: [1], page: 1, lastPage: 5, total: 90);
    expect(page.total, 90);
    expect(page.items, [1]);
    expect(() => page.items.add(2), throwsUnsupportedError);
    expect(
      () => Page<int>(items: [], page: 0, lastPage: 1, total: 0),
      throwsArgumentError,
    );
    final unknown = CommandResult(
      status: CommandStatus.outcomeUnknown,
      scope: BaseFixtures.supervisedVisit,
    );
    expect(unknown.status, CommandStatus.outcomeUnknown);
    final read = ReadFailure<String>(
      PortFailure(kind: FailureKind.forbidden, reasonCode: 'not_assigned'),
    );
    expect(read.failure.kind, FailureKind.forbidden);
  });

  test(
    'navigation IDs, legacy tabs and compatibility aliases preserve meaning',
    () {
      expect(WorkerTab.values.map((v) => v.tabIndex), [0, 1, 2, 3, 4]);
      expect([0, 1, 2, 3].map((i) => tabFromLegacyIndex(i)!.tabIndex), [
        0,
        2,
        1,
        4,
      ]);
      expect(tabFromLegacyIndex(9), isNull);
      expect(
        LegacyRouteAdapter.resolve('cleaning_booking_details', {
          'booking_id': 202,
          'session_id': 302,
          'assignment_id': 402,
        }, origin: RouteOrigin.notification).intent!.scope!.sessionId,
        '302',
      );
      expect(
        LegacyRouteAdapter.resolve('/orderdetails', {
          'orderId': 202,
          'sessionId': 301,
        }).intent!.scope!.sessionId,
        '301',
      );
      expect(
        LegacyRouteAdapter.resolve('/transactiondetails', {
          'disputeId': 44,
        }).intent!.destination,
        WorkerDestination.disputeThread,
      );
      expect(
        LegacyRouteAdapter.resolve(
          '/transactionhistory',
          null,
        ).intent!.destination,
        WorkerDestination.depositLedger,
      );
      expect(
        LegacyRouteAdapter.resolve('/orderdetails', {'sessionId': 4}).errorCode,
        'target_invalid',
      );
      expect(
        LegacyRouteAdapter.resolve('missing_route', null).errorCode,
        'target_unknown',
      );
      expect(
        () => RouteIntent(
          destination: WorkerDestination.earningDetail,
          origin: RouteOrigin.finance,
          entityId: '123',
        ),
        throwsArgumentError,
      );
    },
  );

  test('all base fixtures match V2 JSON catalog identities and core schema', () {
    final path = File(
      'lib/presentation/worker_v2/contracts/fixtures/base_scenarios.json',
    );
    final source = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
    final version = File(
      'lib/presentation/worker_v2/contracts/VERSION',
    ).readAsStringSync().trim();
    expect(source['contractVersion'], version);
    final fixtures = (source['scenarios'] as List).cast<Map<String, dynamic>>();
    expect(fixtures.length, 17);
    expect(
      fixtures.map((f) => f['code']).toSet(),
      BaseFixtures.scenarios.map((f) => f.code).toSet(),
    );
    for (final fixture in fixtures) {
      final scope = fixture['scope'] as Map<String, dynamic>;
      final model = BaseFixtures.scenarios.singleWhere(
        (f) => f.code == fixture['code'],
      );
      expect(scope['bookingId'], model.scope.bookingId);
      expect(scope['sessionId'], model.scope.sessionId);
      expect(scope['assignmentId'], model.scope.assignmentId);
      final owner = fixture['owner'];
      expect(owner, model.operational.executionOwner?.name);
      expect(
        fixture['executionCapability'],
        model.operational.executionCapability,
      );
      expect(
        fixture['canRecordAttendance'],
        model.operational.canRecordAttendance,
      );
      expect(
        (fixture['allowedActions'] as List).toSet(),
        model.operational.allowedActions.map((v) => v.wireName).toSet(),
      );
      expect(
        (fixture['blockedReasons'] as List).toSet(),
        model.operational.blockedReasons,
      );
      final amount = fixture['amount'];
      if (amount != null) {
        final money = MoneyValue(
          decimal: amount['decimal'] as String,
          currency: amount['currency'] as String,
        );
        expect(money.decimal, model.money!.decimal);
      }
      expect(fixture['bookingKind'], model.bookingKind);
      final intervalRows = (fixture['intervals'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      expect(
        intervalRows.map((v) => v['start']),
        model.intervals.map((v) => v.start),
      );
      expect(
        intervalRows.map((v) => v['end']),
        model.intervals.map((v) => v.end),
      );
      expect(fixture.containsKey('startsAt'), model.boundsAmbiguous);
      expect(fixture['discoverable'], model.discoverable);
      expect(fixture['assigned'], model.assigned);
      expect(fixture['totalsByCurrency'] ?? {}, model.totalsByCurrency);
      expect(fixture['depositEligible'], model.depositEligible);
      expect(fixture['notificationId'], model.notificationId);
      expect(fixture['cacheAgeSeconds'], model.cacheAgeSeconds);
      expect(fixture['denied'], model.denied);
      expect(fixture['commandOutcome'], model.commandOutcome?.name);
      if (fixture['disputeId'] != null) {
        expect(fixture['disputeId'], model.destination!.entityId);
      }
      if (fixture['earning'] != null) {
        expect(fixture['earning']['key'], model.earning!.key);
        expect(fixture['earning']['authoritativeAmount'], isNull);
      }
    }
    final schema =
        jsonDecode(
              File(
                'lib/presentation/worker_v2/contracts/fixtures/base_scenarios.schema.json',
              ).readAsStringSync(),
            )
            as Map;
    expect(schema[r'$schema'], 'https://json-schema.org/draft/2020-12/schema');
    expect((schema[r'$defs'] as Map).containsKey('scenario'), isTrue);
  });

  test(
    'all 17 scenarios preserve independent domain authority and visit identity',
    () {
      // These expectations are intentionally separate from the fixture JSON and
      // Dart fixture factory, so two coordinated edits cannot invert a scenario.
      // Values: booking, selected session, assignment, owner, execution, attendance, blocked reasons.
      final expected = <String, List<Object?>>{
        'legacy_single_worker': [
          '101',
          null,
          null,
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
        'standard_kind_supervisor_v2': [
          '202',
          '301',
          '401',
          ExecutionOwner.supervisor,
          false,
          true,
          {'supervisor_managed'},
        ],
        'independent_later_visit': [
          '202',
          '302',
          '402',
          ExecutionOwner.supervisor,
          false,
          true,
          {'not_yet_available'},
        ],
        'room_interval_overlap_gap': [
          '202',
          '301',
          '401',
          ExecutionOwner.supervisor,
          false,
          true,
          {'execution_unavailable'},
        ],
        'ambiguous_bounds': [
          '202',
          '301',
          '401',
          ExecutionOwner.supervisor,
          false,
          true,
          {'unavailable'},
        ],
        'unaccepted_discoverable_offer': [
          '203',
          null,
          null,
          null,
          false,
          false,
          {'not_assigned'},
        ],
        'customer_wait_rework': [
          '202',
          '301',
          '401',
          ExecutionOwner.supervisor,
          false,
          true,
          {'waiting_customer'},
        ],
        'valid_zero_money': [
          '101',
          null,
          null,
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
        'missing_allocation': [
          '202',
          '302',
          '402',
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
        'mixed_currencies': [
          '101',
          null,
          null,
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
        'deposit_restriction': [
          '101',
          null,
          null,
          ExecutionOwner.worker,
          false,
          true,
          {'financial_restriction'},
        ],
        'exact_session_dispute': [
          '202',
          '301',
          '401',
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
        'notification_selected_session': [
          '202',
          '302',
          '402',
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
        'offline_24h_expiry': [
          '202',
          '301',
          '401',
          ExecutionOwner.worker,
          false,
          true,
          {'unavailable'},
        ],
        'assignment_removed': [
          '202',
          '301',
          '401',
          ExecutionOwner.worker,
          false,
          false,
          {'not_assigned'},
        ],
        'stale_409': [
          '202',
          '301',
          '401',
          ExecutionOwner.worker,
          false,
          true,
          {'state_changed'},
        ],
        'uncertain_timeout': [
          '202',
          '301',
          '401',
          ExecutionOwner.worker,
          true,
          true,
          <String>{},
        ],
      };
      expect(
        BaseFixtures.scenarios.map((f) => f.code).toSet(),
        expected.keys.toSet(),
      );
      expect(BaseFixtures.scenarios.length, expected.length);
      for (final fixture in BaseFixtures.scenarios) {
        final e = expected[fixture.code]!;
        expect(fixture.scope.bookingId, e[0], reason: fixture.code);
        expect(fixture.scope.sessionId, e[1], reason: fixture.code);
        expect(fixture.scope.assignmentId, e[2], reason: fixture.code);
        expect(fixture.operational.executionOwner, e[3], reason: fixture.code);
        expect(
          fixture.operational.executionCapability,
          e[4],
          reason: fixture.code,
        );
        expect(
          fixture.operational.canRecordAttendance,
          e[5],
          reason: fixture.code,
        );
        expect(fixture.operational.blockedReasons, e[6], reason: fixture.code);
        expect(
          fixture.operational.allowedActions.map((v) => v.wireName).toSet(),
          fixture.code == 'legacy_single_worker'
              ? {'view', 'start_travel', 'arrive'}
              : {'view'},
          reason: fixture.code,
        );
      }
      final byCode = {for (final f in BaseFixtures.scenarios) f.code: f};
      expect(byCode['standard_kind_supervisor_v2']!.bookingKind, 'standard');
      final overlap = byCode['room_interval_overlap_gap']!.intervals;
      expect(overlap.length, 3);
      expect(
        DateTime.parse(
          overlap[1].start,
        ).isBefore(DateTime.parse(overlap[0].end)),
        true,
      );
      expect(
        DateTime.parse(
          overlap[1].end,
        ).isBefore(DateTime.parse(overlap[2].start)),
        true,
      );
      expect(byCode['ambiguous_bounds']!.boundsAmbiguous, true);
      expect(byCode['unaccepted_discoverable_offer']!.discoverable, true);
      expect(byCode['unaccepted_discoverable_offer']!.assigned, false);
      expect(byCode['valid_zero_money']!.money!.decimal, '0.00');
      expect(
        byCode['missing_allocation']!.earning!.authoritativeAmount,
        isNull,
      );
      expect(byCode['mixed_currencies']!.totalsByCurrency, {
        'USD': '13.25',
        'SYP': '100.00',
      });
      expect(byCode['deposit_restriction']!.depositEligible, false);
      expect(byCode['exact_session_dispute']!.destination!.entityId, '500');
      expect(byCode['notification_selected_session']!.notificationId, '900');
      expect(byCode['offline_24h_expiry']!.cacheAgeSeconds, greaterThan(86400));
      expect(byCode['assignment_removed']!.denied, true);
      expect(byCode['stale_409']!.commandOutcome, CommandStatus.rejected);
      expect(
        byCode['uncertain_timeout']!.commandOutcome,
        CommandStatus.outcomeUnknown,
      );
    },
  );

  test('command identifiers and safe scoped filters remain stable', () {
    final scope = WorkScope(bookingId: '2', sessionId: '3');
    expect(
      SimpleMissionCommand(scope, SimpleMissionAction.confirmWorkStart).type,
      'confirm_work_start',
    );
    expect(
      ExtensionDecisionCommand(
        scope,
        extensionId: '4',
        family: ExtensionRecordFamily.fixedTimeWarning,
        accept: false,
      ).type,
      'reject_extension',
    );
    expect(
      () => OfferDecision(kind: OfferDecisionKind.acceptSelected),
      throwsArgumentError,
    );
    expect(
      OfferDecision(
        kind: OfferDecisionKind.acceptSelected,
        selectedSessionIds: ['3'],
      ).selectedSessionIds,
      ['3'],
    );
    expect(
      AgendaQuery(
        dates: DateRange(from: '2026-10-01', to: '2026-10-31'),
      ).key,
      contains('2026-10-01/2026-10-31'),
    );
    expect(
      () => AgendaQuery(
        dates: DateRange(from: '2026-10-01', to: '2026-11-01'),
      ),
      throwsArgumentError,
    );
    expect(
      () => DateRange(from: '2026-02-30', to: '2026-03-01'),
      throwsArgumentError,
    );
    expect(
      () => AcknowledgeEquipmentCommand(scope, reservationId: ''),
      throwsArgumentError,
    );
    expect(() => PageQuery(page: 0), throwsArgumentError);
    expect(() => PageQuery(perPage: 101), throwsArgumentError);
    expect(
      OfferQuery(status: 'a/b', search: 'c').key,
      isNot(OfferQuery(status: 'a', search: 'b/c').key),
    );
    expect(
      BookingQuery(status: 'a/b', search: 'c').key,
      isNot(BookingQuery(status: 'a', search: 'b/c').key),
    );
  });

  test(
    'decision commands preserve actual endpoint identities and rejection reasons',
    () {
      final legacy = WorkScope(bookingId: '10');
      final visit = WorkScope(bookingId: '10', sessionId: '20');
      final legacyEnd = OpenTimeEndCommand(
        legacy,
        approve: false,
        reason: 'No extension',
      );
      final visitEnd = OpenTimeEndCommand(
        visit,
        approve: false,
        reason: 'Schedule conflict',
      );
      expect(legacyEnd.scope.sessionId, isNull);
      expect(visitEnd.scope.sessionId, '20');
      expect(legacyEnd.reason, 'No extension');
      expect(visitEnd.reason, 'Schedule conflict');
      expect(legacyEnd.type, 'decide_open_time_end');
      final extension = ExtensionDecisionCommand(
        visit,
        extensionId: '30',
        family: ExtensionRecordFamily.fixedTimeWarning,
        accept: false,
        reason: 'Insufficient time',
      );
      expect(extension.extensionId, '30');
      expect(extension.reason, 'Insufficient time');
      expect(extension.type, 'reject_extension');
      final schedule = ScheduleChangeCommand(
        visit,
        changeRequestId: '40',
        approve: false,
        reason: 'Cannot attend',
      );
      expect(schedule.changeRequestId, '40');
      expect(schedule.reason, 'Cannot attend');
      expect(schedule.type, 'decide_schedule_change');
      expect(
        () => ExtensionDecisionCommand(
          visit,
          extensionId: '',
          family: ExtensionRecordFamily.fixedTimeWarning,
          accept: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => ScheduleChangeCommand(visit, changeRequestId: '', approve: true),
        throwsArgumentError,
      );
    },
  );

  test('two special-service lines and two reservation IDs stay disjoint', () {
    final scope = WorkScope(bookingId: '77', sessionId: '88');
    expect(
      SpecialServiceStartCommand(scope, lineId: '11').lineId,
      isNot(SpecialServiceStartCommand(scope, lineId: '12').lineId),
    );
    final unable = SpecialServiceFinishCommand(
      scope,
      lineId: '12',
      status: SpecialServiceFinishStatus.unable,
      reason: 'access_denied',
      afterImages: ['image-ref'],
    );
    expect(unable.status, SpecialServiceFinishStatus.unable);
    expect(unable.reason, 'access_denied');
    expect(unable.afterImages, ['image-ref']);
    expect(
      () => SpecialServiceFinishCommand(
        scope,
        lineId: '11',
        status: SpecialServiceFinishStatus.unable,
      ),
      throwsArgumentError,
    );
    expect(
      AcknowledgeEquipmentCommand(scope, reservationId: '21').reservationId,
      isNot(
        ReturnEquipmentCommand(
          scope,
          reservationId: '22',
          failureReason: 'damaged',
        ).reservationId,
      ),
    );
    final report = CompletionReportCommand(
      WorkScope(bookingId: '77'),
      completionMessage: 'completed',
      cleaningServices: [
        CompletionTaskSnapshot(name: 'service', label: 'Service', sort: 0),
      ],
      propertiesRooms: [
        CompletionTaskSnapshot(name: 'room', label: 'Room', sort: 1),
      ],
    );
    expect(report.cleaningServices.single.name, 'service');
    expect(report.propertiesRooms.single.sort, 1);
    expect(
      () => CompletionReportCommand(
        scope,
        cleaningServices: report.cleaningServices,
      ),
      throwsArgumentError,
    );
    expect(
      SimpleMissionCommand(scope, SimpleMissionAction.receiveMaterials).type,
      'receive_materials',
    );
  });

  test(
    'mission reads provide exact service and reservation identities for commands',
    () {
      final scope = ContractIdentityFixtures.scope;
      final mission = ContractIdentityFixtures.mission;
      final lineCommands = mission.serviceLines
          .map(
            (line) =>
                SpecialServiceStartCommand(line.scope, lineId: line.lineId),
          )
          .toList();
      expect(lineCommands.map((command) => command.lineId), [
        'line-a',
        'line-b',
      ]);
      expect(mission.serviceLines.map((line) => line.label).toSet().length, 1);
      expect(
        mission.serviceLines.every(
          (line) => line.scope.cacheKey == scope.cacheKey,
        ),
        true,
      );

      final reservations = ContractIdentityFixtures.reservations;
      final custodyCommands = reservations
          .map(
            (reservation) => AcknowledgeEquipmentCommand(
              scope,
              reservationId: reservation.reservationId!,
            ),
          )
          .toList();
      expect(custodyCommands.map((command) => command.reservationId), [
        'reservation-9',
        'reservation-10',
      ]);
      for (var index = 0; index < reservations.length; index++) {
        expect(
          custodyCommands[index].reservationId,
          isNot(reservations[index].itemId),
        );
        expect(
          ReturnEquipmentCommand(
            scope,
            reservationId: reservations[index].reservationId!,
          ).reservationId,
          reservations[index].reservationId,
        );
      }

      final identityMissing = InventoryItemView(
        itemId: 'equipment-5',
        name: 'Vacuum',
        quantity: '1',
        custodyState: 'issued',
        allowedActions: {
          WorkerAction.acknowledgeEquipment,
          WorkerAction.returnEquipment,
        },
      );
      expect(identityMissing.allowedActions, isEmpty);
    },
  );

  test(
    'extension commands retain family for colliding IDs and validate minutes',
    () {
      final scope = WorkScope(bookingId: '77', sessionId: '88');
      final warning = ExtensionDecisionCommand(
        scope,
        extensionId: 'same-id',
        family: ExtensionRecordFamily.fixedTimeWarning,
        accept: true,
        additionalMinutes: 15,
      );
      final openTime = ExtensionDecisionCommand(
        scope,
        extensionId: 'same-id',
        family: ExtensionRecordFamily.openTimeExtension,
        accept: false,
        reason: 'schedule_conflict',
      );
      expect(warning.extensionId, openTime.extensionId);
      expect(warning.family, ExtensionRecordFamily.fixedTimeWarning);
      expect(openTime.family, ExtensionRecordFamily.openTimeExtension);
      expect(warning.additionalMinutes, 15);
      expect(openTime.type, 'reject_extension');
      final warningRejection = ExtensionDecisionCommand(
        scope,
        extensionId: 'same-id',
        family: ExtensionRecordFamily.fixedTimeWarning,
        accept: false,
        reason: 'declined',
      );
      expect(warningRejection.type, 'reject_extension');
      expect(
        CommandResult(
          status: CommandStatus.outcomeUnknown,
          scope: scope,
        ).status,
        CommandStatus.outcomeUnknown,
      );
      expect(
        () => ExtensionDecisionCommand(
          scope,
          extensionId: 'same-id',
          family: ExtensionRecordFamily.openTimeExtension,
          accept: true,
          additionalMinutes: 15,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExtensionDecisionCommand(
          scope,
          extensionId: 'same-id',
          family: ExtensionRecordFamily.fixedTimeWarning,
          accept: false,
          additionalMinutes: 15,
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'direct transport imports are forbidden in feature consumers and contracts',
    () {
      for (final source in [
        'package:dio/dio.dart',
        'package:get_it/get_it.dart',
        'package:injectable/injectable.dart',
        'package:dllni_cleaninig_owner_app/core/di/injection.dart',
        'package:dllni_cleaninig_owner_app/features/orders/data/source/orders_remote_data_source.dart',
      ]) {
        expect(
          boundaries.forbiddenImportsForSection(
            section: 'features',
            source: source,
          ),
          isNotEmpty,
        );
      }
      expect(
        boundaries.forbiddenImportsForSection(
          section: 'contracts',
          source: 'package:flutter/material.dart',
        ),
        isNotEmpty,
      );
      expect(
        boundaries.forbiddenImportsForSection(
          section: 'provider',
          source: 'package:dio/dio.dart',
        ),
        isEmpty,
      );
    },
  );
}
