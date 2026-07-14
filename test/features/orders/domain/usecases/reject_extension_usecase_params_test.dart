import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/reject_extension_usecase_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RejectExtensionUsecaseParams', () {
    test('sends a default worker response when no message is provided', () {
      final params = RejectExtensionUsecaseParams(id: 10);

      expect(params.getBody(), <String, dynamic>{
        'message': RejectExtensionUsecaseParams.defaultRejectionMessage,
      });
    });

    test('trims and sends the worker rejection message', () {
      final params = RejectExtensionUsecaseParams(
        id: 10,
        message: '  لا أستطيع تمديد وقت الخدمة اليوم.  ',
      );

      expect(params.getBody(), <String, dynamic>{
        'message': 'لا أستطيع تمديد وقت الخدمة اليوم.',
      });
    });
  });
}
