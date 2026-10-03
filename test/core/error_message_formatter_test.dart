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

    test('does not expose unknown English server messages', () {
      const message = 'Unable to load data from server';
      expect(
        ErrorMessageFormatter.format(message),
        ErrorMessageFormatter.defaultFallback,
      );
    });

    test('translates neighborhood coverage accept failure', () {
      expect(
        ErrorMessageFormatter.format(
          "This booking is outside the worker's active neighborhoods.",
        ),
        'هذا الطلب خارج الأحياء النشطة المحددة ضمن مناطق عملك.',
      );
    });

    test('translates schedule conflict failure', () {
      expect(
        ErrorMessageFormatter.format(
          'This booking overlaps another confirmed booking in your schedule.',
        ),
        'لا يمكن تنفيذ العملية لأن موعد هذا الطلب يتعارض مع حجز مؤكد آخر في جدولك.',
      );
    });

    test('uses Arabic fallback even when caller supplies an English fallback', () {
      expect(
        ErrorMessageFormatter.format(
          'Unexpected backend validation failure',
          fallback: 'fallback',
        ),
        ErrorMessageFormatter.defaultFallback,
      );
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
