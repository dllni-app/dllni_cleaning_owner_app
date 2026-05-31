import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/helpers/worker_profile_completeness_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('evaluateWorkerProfileCompleteness', () {
    test(
      'returns complete when location/work areas/working time are valid',
      () {
        final result = evaluateWorkerProfileCompleteness(
          _buildProfile(
            withLocation: true,
            withWorkAreas: true,
            withWorkingTime: true,
          ),
        );

        expect(result.hasMissionStartLocation, isTrue);
        expect(result.hasWorkAreas, isTrue);
        expect(result.hasWorkingTime, isTrue);
        expect(result.isComplete, isTrue);
        expect(result.missingSectionsAr, isEmpty);
      },
    );

    test('marks missing location only', () {
      final result = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: false,
          withWorkAreas: true,
          withWorkingTime: true,
        ),
      );

      expect(result.hasMissionStartLocation, isFalse);
      expect(result.hasWorkAreas, isTrue);
      expect(result.hasWorkingTime, isTrue);
      expect(result.missingSectionsAr, <String>[profileLocationSectionLabelAr]);
    });

    test('marks missing work areas only', () {
      final result = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: true,
          withWorkAreas: false,
          withWorkingTime: true,
        ),
      );

      expect(result.hasMissionStartLocation, isTrue);
      expect(result.hasWorkAreas, isFalse);
      expect(result.hasWorkingTime, isTrue);
      expect(result.missingSectionsAr, <String>[
        profileWorkAreasSectionLabelAr,
      ]);
    });

    test('marks missing working time only', () {
      final result = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: true,
          withWorkAreas: true,
          withWorkingTime: false,
        ),
      );

      expect(result.hasMissionStartLocation, isTrue);
      expect(result.hasWorkAreas, isTrue);
      expect(result.hasWorkingTime, isFalse);
      expect(result.missingSectionsAr, <String>[
        profileWorkingTimeSectionLabelAr,
      ]);
    });

    test('returns multiple missing sections in order', () {
      final result = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: false,
          withWorkAreas: false,
          withWorkingTime: true,
        ),
      );

      expect(result.missingSectionsAr, <String>[
        profileLocationSectionLabelAr,
        profileWorkAreasSectionLabelAr,
      ]);
    });

    test('treats malformed/empty periods as missing working time', () {
      final result = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: true,
          withWorkAreas: true,
          withWorkingTime: true,
          malformedWorkingTime: true,
        ),
      );

      expect(result.hasWorkingTime, isFalse);
      expect(result.missingSectionsAr, <String>[
        profileWorkingTimeSectionLabelAr,
      ]);
    });
  });

  group('WorkerProfileCompletenessPromptGate', () {
    setUp(WorkerProfileCompletenessPromptGate.resetForTests);

    test('prompts once when profile is incomplete', () {
      final incomplete = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: false,
          withWorkAreas: true,
          withWorkingTime: true,
        ),
      );

      expect(
        WorkerProfileCompletenessPromptGate.consumeShouldPrompt(incomplete),
        isTrue,
      );
      expect(
        WorkerProfileCompletenessPromptGate.consumeShouldPrompt(incomplete),
        isFalse,
      );
    });

    test('does not prompt for complete profile', () {
      final complete = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: true,
          withWorkAreas: true,
          withWorkingTime: true,
        ),
      );

      expect(
        WorkerProfileCompletenessPromptGate.consumeShouldPrompt(complete),
        isFalse,
      );
    });
  });

  group('isProfileSectionIncompleteByIndex', () {
    test('maps profile sections to completeness state', () {
      final result = evaluateWorkerProfileCompleteness(
        _buildProfile(
          withLocation: false,
          withWorkAreas: false,
          withWorkingTime: true,
        ),
      );

      expect(isProfileSectionIncompleteByIndex(0, result), isFalse);
      expect(isProfileSectionIncompleteByIndex(1, result), isTrue);
      expect(isProfileSectionIncompleteByIndex(2, result), isTrue);
      expect(isProfileSectionIncompleteByIndex(3, result), isFalse);
      expect(isProfileSectionIncompleteByIndex(4, result), isFalse);
    });
  });
}

FetchWorkerProfileUsecaseModelData _buildProfile({
  required bool withLocation,
  required bool withWorkAreas,
  required bool withWorkingTime,
  bool malformedWorkingTime = false,
}) {
  final workingDay = malformedWorkingTime
      ? WorkingDay(
          isWorking: true,
          hours: [
            WorkingDayItem(from: '25:10', to: '09:00'),
            WorkingDayItem(from: '', to: ''),
          ],
        )
      : WorkingDay(
          isWorking: true,
          hours: [WorkingDayItem(from: '09:00', to: '12:00')],
        );

  return FetchWorkerProfileUsecaseModelData(
    homeAddress: withLocation ? '36.202100, 37.134300' : null,
    homeLatitude: withLocation ? 36.2021 : null,
    homeLongitude: withLocation ? 37.1343 : null,
    zones: withWorkAreas
        ? [Zone(name: 'الجميلية', isActive: true)]
        : [Zone(name: 'منطقة غير مفعلة', isActive: false)],
    defaultWorkingHours: FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
      sunday: withWorkingTime
          ? workingDay
          : WorkingDay(isWorking: false, hours: []),
      monday: WorkingDay(isWorking: false, hours: []),
      tuesday: WorkingDay(isWorking: false, hours: []),
      wednesday: WorkingDay(isWorking: false, hours: []),
      thursday: WorkingDay(isWorking: false, hours: []),
      friday: WorkingDay(isWorking: false, hours: []),
      saturday: WorkingDay(isWorking: false, hours: []),
    ),
  );
}
