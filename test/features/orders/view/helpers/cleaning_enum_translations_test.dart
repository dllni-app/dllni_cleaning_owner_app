import 'package:dllni_cleaninig_owner_app/features/orders/view/helpers/cleaning_enum_translations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CleaningEnumTranslations', () {
    test('prefers translated cleaning mode when backend label is English', () {
      expect(
        CleaningEnumTranslations.preferArabicLabel(
          'deep',
          'deep',
          CleaningEnumTranslations.cleaningMode,
        ),
        'تنظيف عميق',
      );
    });

    test('keeps backend label when it is already Arabic', () {
      expect(
        CleaningEnumTranslations.preferArabicLabel(
          'تنظيف عادي',
          'regular',
          CleaningEnumTranslations.cleaningMode,
        ),
        'تنظيف عادي',
      );
    });
  });
}
