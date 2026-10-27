import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/common.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/contracts/models.dart';
import 'package:dllni_cleaninig_owner_app/presentation/worker_v2/features/mission/mission_sos_window_policy.dart';
import 'package:flutter_test/flutter_test.dart';

MissionView _mission({
  DateTime? scheduledStartsAt,
  DateTime? startedAt,
  String status = 'assigned',
  String assignmentStatus = 'accepted',
}) => MissionView(
  scope: WorkScope(bookingId: 'booking-1', sessionId: 'visit-1'),
  status: status,
  stage: 'ready',
  ownAssignmentStatus: assignmentStatus,
  operational: OperationalContext(
    executionOwner: ExecutionOwner.supervisor,
    executionCapability: false,
    canRecordAttendance: true,
    allowedActions: {WorkerAction.sendSos},
  ),
  ownServices: const [],
  ownRooms: const [],
  waitingReasons: const [],
  scheduledStartsAt: scheduledStartsAt,
  startedAt: startedAt,
);

void main() {
  final now = DateTime.utc(2026, 11, 2, 10, 0);

  test('before one-hour scheduled window is not eligible', () {
    expect(
      MissionSosWindowPolicy.permits(
        _mission(scheduledStartsAt: now.add(const Duration(minutes: 61))),
        now: now,
      ),
      isFalse,
    );
  });

  test('at exactly one hour SOS becomes eligible', () {
    expect(
      MissionSosWindowPolicy.permits(
        _mission(scheduledStartsAt: now.add(const Duration(hours: 1))),
        now: now,
      ),
      isTrue,
    );
  });

  test('missing appointment is not interpreted as current time', () {
    expect(MissionSosWindowPolicy.permits(_mission(), now: now), isFalse);
  });

  test('active mission retains emergency access with missing appointment', () {
    expect(
      MissionSosWindowPolicy.permits(
        _mission(startedAt: now.subtract(const Duration(minutes: 2))),
        now: now,
      ),
      isTrue,
    );
    expect(
      MissionSosWindowPolicy.permits(_mission(status: 'in_progress'), now: now),
      isTrue,
    );
  });

  test('closed or unassigned missions cannot show SOS', () {
    expect(
      MissionSosWindowPolicy.permits(
        _mission(
          scheduledStartsAt: now.subtract(const Duration(days: 1)),
          status: 'completed',
        ),
        now: now,
      ),
      isFalse,
    );
    expect(
      MissionSosWindowPolicy.permits(
        _mission(
          startedAt: now.subtract(const Duration(minutes: 1)),
          assignmentStatus: 'cancelled',
        ),
        now: now,
      ),
      isFalse,
    );
  });
}
