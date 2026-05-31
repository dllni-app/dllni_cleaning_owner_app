import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_profile_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpdateWorkerProfileParams', () {
    test('includes home location fields when provided', () {
      final params = UpdateWorkerProfileParams(
        homeLatitude: 36.2021,
        homeLongitude: 37.1343,
        homeAddress: '36.202100, 37.134300',
      );

      expect(params.getBody(), <String, dynamic>{
        'homeLatitude': 36.2021,
        'homeLongitude': 37.1343,
        'homeAddress': '36.202100, 37.134300',
      });
    });
  });
}
