import 'package:common_package/helpers/error_message_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessageFormatter', () {
    test('returns fallback for null or empty message', () {
      expect(
        ErrorMessageFormatter.format(null, fallback: 'fallback'),
        'fallback',
      );
      expect(
        ErrorMessageFormatter.format('   ', fallback: 'fallback'),
        'fallback',
      );
    });

    test('returns server message unchanged', () {
      const message = 'تعذر تحميل البيانات من الخادم';
      expect(ErrorMessageFormatter.format(message), message);
    });

    test('returns English server message unchanged', () {
      const message = 'Unable to load data from server';
      expect(ErrorMessageFormatter.format(message), message);
    });

    test('returns fallback for unknown locale key without translation', () {
      expect(
        ErrorMessageFormatter.format(
          'errorMessage.defaultError',
          fallback: 'حدث خطأ',
        ),
        'حدث خطأ',
      );
    });

    test('returns fallback for validation locale key without translation', () {
      expect(
        ErrorMessageFormatter.format(
          'validation.requiredField',
          fallback: 'حقل مطلوب',
        ),
        'حقل مطلوب',
      );
    });
  });
}
