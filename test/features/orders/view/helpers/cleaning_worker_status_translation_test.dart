import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_worker_order_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'preserves authorized team supervisor contact through lifecycle updates',
    () {
      final order = fetchOrdersUsecaseModelDataItemFromJson(<String, dynamic>{
        'bookingKind': 'standard',
        'numberOfWorkers': 2,
        'status': 'worker_assigned',
        'supervisorContact': <String, dynamic>{
          'id': 7,
          'name': 'مشرف الفريق',
          'phone': '+963944100006',
        },
      });
      expect(order.supervisorContact?.firstName, 'مشرف الفريق');
      expect(order.supervisorContact?.phone, '+963944100006');
      expect(
        order
            .withLifecycle(startedTravelAt: '2026-10-27T12:00:00Z')
            .supervisorContact
            ?.phone,
        '+963944100006',
      );
      expect(order.toJson()['supervisorContact'], isNotNull);
    },
  );
  test('all known worker order statuses display in Arabic', () {
    final expected = <String, String>{
      'pending': 'بانتظار القبول',
      'accepted': 'تم القبول',
      'accepted_waiting_team': 'تم القبول - بانتظار اكتمال الفريق',
      'accepted_waiting_for_order_start': 'تم القبول - بانتظار بدء الطلب',
      'worker_assigned': 'تم تعيين العامل',
      'awaiting_start_verification': 'بانتظار تأكيد رمز الوصول',
      'awaiting_worker_start_confirmation': 'بانتظار بدء العمل من العامل',
      'start_approved': 'تم تأكيد بدء العمل - بانتظار باقي العمال',
      'rejected': 'تم رفض الطلب',
      'withdrawn': 'تم الانسحاب من الطلب',
      'in_progress': 'قيد التنفيذ',
      'awaiting_customer_completion': 'بانتظار تأكيد العميل للإنهاء',
      'time_extension_requested': 'طلب تمديد وقت',
      'under_dispute': 'قيد المراجعة',
      'completed': 'مكتمل',
      'cancelled': 'ملغي',
      'scheduled': 'مجدول',
      'partially_completed': 'مكتمل جزئياً',
    };
    for (final entry in expected.entries) {
      expect(
        arabicCleaningStatusLabel(entry.key),
        entry.value,
        reason: entry.key,
      );
      expect(
        arabicCleaningStatusLabel(entry.key.replaceAll('_', ' ')),
        entry.value,
        reason: 'space-separated ${entry.key}',
      );
      expect(
        arabicCleaningStatusLabel(entry.key.replaceAll('_', '-')),
        entry.value,
        reason: 'hyphen-separated ${entry.key}',
      );
    }
  });

  test('never displays unknown English raw status', () {
    expect(arabicCleaningStatusLabel('unmapped_new_state'), 'قيد المتابعة');
    expect(
      arabicCleaningStatusLabel('unmapped status', fallback: 'بانتظار البدء'),
      'بانتظار البدء',
    );
    expect(arabicCleaningStatusLabel('بانتظار المشرف'), 'بانتظار المشرف');
  });
}
