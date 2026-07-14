import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_team_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleaning team assignment models', () {
    test('parses lifecycle timestamps for the authenticated assignment', () {
      final assignment = CleaningMyAssignmentModel.fromJson(
        <String, dynamic>{
          'id': 10,
          'workerId': 4,
          'status': 'awaiting_start_verification',
          'acceptedAt': '2026-07-14T10:00:00Z',
          'startedTravelAt': '2026-07-14T10:05:00Z',
          'arrivedAt': '2026-07-14T10:20:00Z',
          'startApprovedAt': '2026-07-14T10:22:00Z',
          'workStartedAt': '2026-07-14T10:23:00Z',
          'workFinishedAt': '2026-07-14T11:30:00Z',
        },
      );

      expect(assignment.startedTravelAt, '2026-07-14T10:05:00Z');
      expect(assignment.arrivedAt, '2026-07-14T10:20:00Z');
      expect(assignment.startApprovedAt, '2026-07-14T10:22:00Z');
      expect(assignment.workStartedAt, '2026-07-14T10:23:00Z');
      expect(assignment.workFinishedAt, '2026-07-14T11:30:00Z');
    });

    test('parses snake case lifecycle timestamp aliases', () {
      final assignment = CleaningWorkerAssignmentModel.fromJson(
        <String, dynamic>{
          'id': 11,
          'worker_id': 5,
          'started_travel_at': '2026-07-14T12:00:00Z',
          'arrived_at': '2026-07-14T12:10:00Z',
          'start_approved_at': '2026-07-14T12:12:00Z',
          'work_started_at': '2026-07-14T12:13:00Z',
          'work_finished_at': '2026-07-14T13:00:00Z',
        },
      );

      expect(assignment.startedTravelAt, '2026-07-14T12:00:00Z');
      expect(assignment.arrivedAt, '2026-07-14T12:10:00Z');
      expect(assignment.startApprovedAt, '2026-07-14T12:12:00Z');
      expect(assignment.workStartedAt, '2026-07-14T12:13:00Z');
      expect(assignment.workFinishedAt, '2026-07-14T13:00:00Z');
    });
  });
}
