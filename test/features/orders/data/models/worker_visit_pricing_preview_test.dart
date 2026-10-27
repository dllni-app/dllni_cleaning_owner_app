import 'package:flutter_test/flutter_test.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';

void main() {
  test('visit pricing preview preserves source worker entitlement', () {
    final session = WorkerBookingSessionModel.fromJson({
      'id': 19,
      'sequence': 2,
      'status': 'scheduled',
      'pricingPreview': {
        'serviceShareAmount': 12500,
        'travelFee': 1500,
        'adminMarginAmount': 3000,
        'workerAmount': 14000,
        'currency': 'SYP',
      },
    });

    expect(session.id, 19);
    expect(session.pricingPreview?.workerAmount, 14000);
    expect(session.pricingPreview?.travelFee, 1500);
    expect(session.pricingPreview?.serviceShareAmount, 12500);
    expect(session.pricingPreview?.currency, 'SYP');
    expect(session.financial, isNull);
  });

  test('unknown visit pricing stays absent rather than inferred', () {
    final session = WorkerBookingSessionModel.fromJson({
      'id': 20,
      'status': 'scheduled',
      'pricingPreview': null,
    });
    expect(session.pricingPreview, isNull);
  });
}
