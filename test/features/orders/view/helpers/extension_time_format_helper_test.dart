import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/extension_time_format_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatExtensionDurationAr', () {
    test('formats one hour', () {
      expect(formatExtensionDurationAr(60), 'ساعة إضافية');
    });

    test('formats two hours', () {
      expect(formatExtensionDurationAr(120), 'ساعتان إضافيتان');
    });

    test('formats minutes', () {
      expect(formatExtensionDurationAr(30), '30 دقيقة إضافية');
    });
  });
}
