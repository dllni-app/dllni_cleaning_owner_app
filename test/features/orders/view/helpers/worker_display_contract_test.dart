import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_team_models.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_enum_translations.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/order_lifecycle_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('worker display contract', () {
    test('occasion labels match the user app names', () {
      expect(CleaningEnumTranslations.eventType('family_dinner'), 'عشاء عائلي');
      expect(CleaningEnumTranslations.eventType('birthday'), 'حفلة عيد ميلاد');
      expect(
        CleaningEnumTranslations.eventType('birthday_party'),
        'حفلة عيد ميلاد',
      );
      expect(CleaningEnumTranslations.eventType('large_gathering'), 'عزيمة كبيرة');
      expect(CleaningEnumTranslations.eventType('funeral'), 'عزاء');
      expect(CleaningEnumTranslations.eventType('condolences'), 'عزاء');
    });

    test('pending order keeps customer location hidden before acceptance', () {
      final order = FetchOrdersUsecaseModelDataItem(
        status: CleaningBookingStatus.pending,
      );

      expect(OrderLifecyclePolicy.isCustomerDataHidden(order), isTrue);
    });

    test('pending team order reveals full location after this worker accepts', () {
      final order = FetchOrdersUsecaseModelDataItem(
        status: CleaningBookingStatus.pending,
        assignmentMode: 'open_count',
        numberOfWorkers: 2,
        myAssignment: CleaningMyAssignmentModel(
          status: 'accepted',
          acceptedAt: '2026-08-18T18:00:00Z',
        ),
      );

      expect(OrderLifecyclePolicy.hasCurrentWorkerAccepted(order), isTrue);
      expect(OrderLifecyclePolicy.isCustomerDataHidden(order), isFalse);
    });
  });
}
