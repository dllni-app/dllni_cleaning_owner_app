import 'package:dllni_cleaninig_owner_app/features/orders/data/models/security_code_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityCodeModel', () {
    test('parses nested camelCase payload', () {
      final model = SecurityCodeModel.fromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'securityCode': '4321',
          'expiresAt': '2026-05-17T12:00:00Z',
        },
      });

      expect(model.data?.securityCode, '4321');
      expect(model.data?.expiresAt, '2026-05-17T12:00:00Z');
    });

    test('parses nested snake_case payload', () {
      final model = SecurityCodeModel.fromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'security_code': '9876',
          'expires_at': '2026-05-17T12:15:00Z',
        },
      });

      expect(model.data?.securityCode, '9876');
      expect(model.data?.expiresAt, '2026-05-17T12:15:00Z');
    });

    test('parses flat snake_case payload without data wrapper', () {
      final model = SecurityCodeModel.fromJson(<String, dynamic>{
        'security_code': '1111',
        'expires_at': '2026-05-17T12:30:00Z',
      });

      expect(model.data?.securityCode, '1111');
      expect(model.data?.expiresAt, '2026-05-17T12:30:00Z');
    });

    test('extracts code embedded in arrive-style booking payload', () {
      final model = SecurityCodeModel.tryFromBookingPayload(<String, dynamic>{
        'id': 42,
        'status': 'awaiting_start_verification',
        'verification_code': '5555',
        'expires_at': '2026-05-17T13:00:00Z',
      });

      expect(model?.data?.securityCode, '5555');
      expect(model?.data?.expiresAt, '2026-05-17T13:00:00Z');
    });
  });
}
