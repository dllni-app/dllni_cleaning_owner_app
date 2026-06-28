import 'package:intl_phone_number_input/intl_phone_number_input.dart';

const String defaultPhoneIsoCode = 'SY';
const String _requiredPhoneMessage = 'Ø£Ø¯Ø®Ù„ Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„';
const String _invalidPhoneMessage = 'Ø±Ù‚Ù… Ø§Ù„Ø¬ÙˆØ§Ù„ ØºÙŠØ± ØµØ§Ù„Ø­';

// Future<PhoneNumber?> parseInitialPhone(String? stored) async {
//   final value = stored?.trim() ?? '';
//   if (value.isEmpty) return null;
//
//   try {
//     final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(
//       value,
//       defaultPhoneIsoCode,
//     );
//     if (parsed.isoCode != defaultPhoneIsoCode) return null;
//     return parsed;
//   } catch (_) {
//     final digits = value.replaceAll(RegExp(r'\D'), '');
//     if (digits.isEmpty) return null;
//     return PhoneNumber(isoCode: defaultPhoneIsoCode, phoneNumber: digits);
//   }
// }

String? formatPhoneForApi(PhoneNumber? number) {
  final value = number?.phoneNumber?.trim();
  if (value == null || value.isEmpty) return null;
  return value.startsWith('+') ? value : '+$value';
}

Future<String?> validatePhoneNumber(PhoneNumber? number) async {
  final raw = number?.phoneNumber?.trim() ?? '';
  if (raw.isEmpty) return _requiredPhoneMessage;

  try {
    final parsed = await PhoneNumber.getRegionInfoFromPhoneNumber(
      raw,
      defaultPhoneIsoCode,
    );
    if (parsed.isoCode != defaultPhoneIsoCode) return _invalidPhoneMessage;

    final normalized = parsed.phoneNumber?.trim() ?? '';
    if (normalized.isEmpty) return _invalidPhoneMessage;

    final digits = normalized.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return _invalidPhoneMessage;
    return null;
  } catch (_) {
    return _invalidPhoneMessage;
  }
}

String? validatePhoneNumberText(String? value) {
  if (value == null || value.trim().isEmpty) return _requiredPhoneMessage;
  return null;
}
