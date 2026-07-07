import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_working_hours_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateWorkerWorkingHoursParams', () {
    test('getBody includes all seven day keys', () {
      final params = UpdateWorkerWorkingHoursParams(
        defaultWorkingHours: FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
          sunday: WorkingDay(isWorking: false, hours: const []),
          monday: WorkingDay(
            isWorking: true,
            hours: [WorkingDayItem(from: '09:00', to: '17:00')],
          ),
          tuesday: WorkingDay(isWorking: false, hours: const []),
          wednesday: WorkingDay(isWorking: false, hours: const []),
          thursday: WorkingDay(isWorking: false, hours: const []),
          friday: WorkingDay(isWorking: false, hours: const []),
          saturday: WorkingDay(isWorking: false, hours: const []),
        ),
      );

      final body = params.getBody();
      final hours = body['defaultWorkingHours'] as Map<String, dynamic>;

      expect(hours.keys, containsAll(<String>[
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
        'saturday',
      ]));
    });

    test('serializes period as single-key object', () {
      final params = UpdateWorkerWorkingHoursParams(
        defaultWorkingHours: FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
          monday: WorkingDay(
            isWorking: true,
            hours: [WorkingDayItem(from: '09:00', to: '17:00')],
          ),
        ),
      );

      final body = params.getBody();
      final monday = (body['defaultWorkingHours'] as Map)['monday'] as Map;

      expect(monday['available'], isTrue);
      expect(monday['data'], [
        {'09:00': '17:00'},
      ]);
    });

    test('serializes unavailable day with empty data', () {
      final params = UpdateWorkerWorkingHoursParams(
        defaultWorkingHours: FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
          sunday: WorkingDay.offline(),
        ),
      );

      final body = params.getBody();
      final hours = body['defaultWorkingHours'] as Map<String, dynamic>;

      expect(hours['sunday'], {'available': false, 'data': <Map<String, String>>[]});
      expect(hours['friday'], {'available': false, 'data': <Map<String, String>>[]});
      expect(hours['saturday'], {'available': false, 'data': <Map<String, String>>[]});
    });

    test('always serializes all seven days even when only one is set', () {
      final params = UpdateWorkerWorkingHoursParams(
        defaultWorkingHours: FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
          wednesday: WorkingDay(
            isWorking: true,
            hours: [WorkingDayItem(from: '09:00', to: '12:00')],
          ),
        ),
      );

      final body = params.getBody();
      final hours = body['defaultWorkingHours'] as Map<String, dynamic>;

      expect(hours.length, 7);
      expect(hours['wednesday'], {
        'available': true,
        'data': [
          {'09:00': '12:00'},
        ],
      });
      expect(hours['friday'], {'available': false, 'data': <Map<String, String>>[]});
    });
  });
}
