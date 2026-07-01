import 'package:intl/intl.dart';

// 1. تحديث الـ Extension ليشمل الـ num
extension NumberFormatting on num? {
  String formatMoney({String currency = 'ل.س'}) {
    if (this == null) return '0 $currency';

    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(this!.truncate());

    if (currency.trim().isEmpty) return formatted;
    return '$formatted $currency';
  }
}

extension PhoneNumberFormatting on String? {
  String get formatAsPhoneNumber {
    if (this == null || this!.isEmpty) return '-';

    // 1. إزالة أي رموز غير رقمية
    String cleaned = this!.replaceAll(RegExp(r'\D'), '');

    // 2. التحقق من طول الرقم (يجب أن يكون طويلاً بما يكفي)
    // نفترض أن الرقم السوري يبدأ بـ 963 يتبعه 9 أرقام (إجمالي 12 رقماً)
    if (cleaned.startsWith('963') && cleaned.length >= 12) {
      String prefix = cleaned.substring(0, 3); // 963
      String part1 = cleaned.substring(3, 6);  // 964
      String part2 = cleaned.substring(6, 9);  // 786
      String part3 = cleaned.substring(9);     // 134

      // التنسيق النهائي: +963 964 786 134
      return '\u200E+$prefix $part1 $part2 $part3';
    }

    // في حال لم يطابق التنسيق المطلوب، نرجعه كما هو مع إضافة + إذا لزم الأمر
    return '\u200E${this!.startsWith('+') ? '' : '+'}$cleaned';
  }
}

// 1. تحديث الـ Extension ليشمل الـ num
