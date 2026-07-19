import 'package:dllni_cleaninig_owner_app/features/profile/data/models/worker_dispatch_eligibility_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerDispatchEligibilityModel', () {
    test('shows an explicit admin suspension warning', () {
      final model = WorkerDispatchEligibilityModel.fromJson(
        <String, dynamic>{
          'canReceiveNewRequests': false,
          'canAcceptNewBookings': false,
          'reasonCode': 'worker_suspended',
          'message':
              'Your worker account was stopped by the admin. You will not receive new orders.',
        },
      );

      expect(model.blocksNewRequests, isTrue);
      expect(model.isAdminSuspended, isTrue);
      expect(model.userMessageAr, contains('تم إيقاف حسابك من قبل الإدارة'));
      expect(model.userMessageAr, contains('لن تستقبل طلبات جديدة'));
    });

    test('does not mark other eligibility failures as admin suspension', () {
      final model = WorkerDispatchEligibilityModel.fromJson(
        <String, dynamic>{
          'canReceiveNewRequests': false,
          'canAcceptNewBookings': false,
          'reasonCode': 'deposit_below_allowed_balance',
        },
      );

      expect(model.blocksNewRequests, isTrue);
      expect(model.isAdminSuspended, isFalse);
    });
  });
}
