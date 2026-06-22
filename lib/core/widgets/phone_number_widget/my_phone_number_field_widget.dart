import 'dart:async';
import 'package:common_package/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'my_custom_phone_field_widget.dart';

class MyPhoneNumberField extends StatelessWidget {
  MyPhoneNumberField({
    super.key,
    this.hintText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.labelText,

    this.labelStyle,

    this.fillColor,
    this.readOnly = false,
    this.keyboardType,
    this.height,
    this.width,
    this.textAlign,
    this.hintStyle,
    this.borderRadius = 16.0,
    this.borderWidth = 1,
    this.obscureText = false,
    this.contentPadding,
    this.style,
    this.isMargin = true,
    this.invalidNumberMessage,
    this.onCountryChanged,
    this.textInputAction,
    this.enabled = true,
    this.initialCountryCode = 'SY',
    this.internationalPhoneValue, // <— الجديد
    // this.nextFocusNode, // <— الجديد
  });

  final Function(Country)? onCountryChanged;

  final TextEditingController controller=TextEditingController();

  // final FocusNode? nextFocusNode;

  final String? hintText;
  final String? labelText;
  final FutureOr<String?> Function(PhoneNumber?)? validator;
  final void Function(PhoneNumber)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final Color? fillColor;
  final bool readOnly;
  final bool obscureText;
  final double? height;
  final double? width;
  final double borderRadius;
  final double borderWidth;
  final TextInputType? keyboardType;
  final TextAlign? textAlign;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? style;
  final EdgeInsetsGeometry? contentPadding;
  final bool isMargin;
  final bool enabled;
  final String? invalidNumberMessage;
  final String initialCountryCode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  /// يحمل دائمًا الرقم الدولي مثل +9639XXXXXXX
  final ValueNotifier<String>? internationalPhoneValue; // <— الجديد

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseDecoration = const InputDecoration().applyDefaults(
      theme.inputDecorationTheme,
    );

    // 🟢 1. نحصل على القيمة الحالية (قد تكون فارغة أو تحتوي +)
    String initialValue = internationalPhoneValue?.value.trim() ?? '';

    // 🟢 2. نحدّد الدولة والرقم بناءً على القيمة
    String countryCode = '+963';
    String countryISO = 'SY';
    String localNumber = '';

    if (initialValue.isNotEmpty && initialValue.startsWith('+')) {
      // مثال: +963947861234 → نستخرج الدولة والرقم
      for (final c in countries) {
        if (initialValue.startsWith('+${c.fullCountryCode}')) {
          countryCode = '+${c.dialCode}';
          countryISO = c.code;
          localNumber = initialValue.replaceFirst('+${c.fullCountryCode}', '');
          break;
        }
      }
    }

    // 🟢 3. نضبط النص الابتدائي في الـ controller
    if (controller.text.isEmpty && localNumber.isNotEmpty) {
      controller.text = localNumber;
    }

    // 🟢 4. نضبط الدولة الابتدائية على حسب ما وجدناه
    final effectiveCountryCode =
    initialValue.isEmpty ? initialCountryCode : countryISO;

    // دالة مساعدة: تحدّث الـ ValueNotifier بالقيمة الدولية
    void _updateIntlByParts({required String countryCodeWithPlus}) {
      if (internationalPhoneValue == null) return;
      String raw = controller.text.trim().replaceAll(RegExp(r'\D'), '');
      if (raw.startsWith('0')) raw = raw.substring(1);
      internationalPhoneValue!.value = '$countryCodeWithPlus$raw';
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: isMargin
            ? EdgeInsets.symmetric(vertical: context.width * 0.04)
            : null,
        height: height,
        width: width,
        child: MyCustomIntlField(
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onCountryChanged: (country) {
            // حدّث الرقم الدولي عند تغيير الدولة
            _updateIntlByParts(countryCodeWithPlus: '+${country.dialCode}');
            if (onCountryChanged != null) onCountryChanged!(country);
          },
          enabled: enabled,
          invalidNumberMessage: invalidNumberMessage,
          pickerDialogStyle: PickerDialogStyle(
            countryCodeStyle: const TextStyle(
              color: Color(0xff2F2B3D),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            countryNameStyle: const TextStyle(
              color: Color(0xff2F2B3D),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            searchFieldInputDecoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              filled: true,
              fillColor: const Color(0xffF9FAFB),
              labelStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
              floatingLabelStyle: const TextStyle(
                color: Color(0xff1E2A78),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xffE5E7EB),
                ),
              ),
            ),
          ),
          showDropdownIcon: true,
          focusNode: focusNode,
          controller: controller,
          // عند تغيير الرقم من المستخدم
          onChanged: (phone) {
            // phone.countryCode مثل +963 و phone.number هو الرقم المحلي
            if (internationalPhoneValue != null) {
              String raw = phone.number.replaceAll(RegExp(r'\D'), '');
              if (raw.startsWith('0')) raw = raw.substring(1);
              internationalPhoneValue!.value = '${phone.countryCode}$raw';
            }
            if (onChanged != null) onChanged!(phone);
          },
          readOnly: readOnly,
          validator: validator,
          obscureText: obscureText,
          initialCountryCode: effectiveCountryCode,


          textAlign: textAlign ?? TextAlign.start,
          keyboardType: keyboardType ?? TextInputType.phone,
          style: const TextStyle(
            color: Color(0xff2F2B3D),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: baseDecoration.copyWith(
            labelText: labelText,

            hintText: hintText,
            filled: true,
            fillColor: const Color(0xffF9FAFB),

            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xffE5E7EB),
                width: 1,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xff1E2A78),
                width: 1.2,
              ),
            ),

            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),

            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class MyPhoneNumberInitField extends StatelessWidget {
//   MyPhoneNumberInitField({
//     super.key,
//     required this.internationalPhoneValue,
//     required this.initialPhoneNumber,
//     required this.controller,
//     required this.labelText,
//
//     this.hintText,
//     this.validator,
//     this.onChanged,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.focusNode,
//     this.fillColor,
//     this.readOnly = false,
//     this.keyboardType,
//     this.height,
//     this.width,
//     this.textAlign,
//     this.hintStyle,
//     this.borderRadius = 16.0,
//     this.borderWidth = 1,
//     this.obscureText = false,
//     this.contentPadding,
//     this.style,
//     this.isMargin = true,
//     this.invalidNumberMessage,
//     this.onCountryChanged,
//     this.textInputAction,
//     this.enabled = true,
//     this.initialCountryCode = 'SY',
//     // الرقم الدولي المبدئي +963...
//   }) {
//     // إذا تم تمرير رقم مبدئي، نقوم بفصله لرمز دولة + رقم محلي
//     if (initialPhoneNumber != null && initialPhoneNumber!.startsWith('+')) {
//       final match = RegExp(
//         r'^\+(\d{1,3})(.*)$',
//       ).firstMatch(initialPhoneNumber!);
//       if (match != null) {
//         final countryDial = match.group(1)!;
//         final local = match.group(2)!.trim();
//         _initialCountryDialCode = countryDial;
//         controller.text = local;
//         internationalPhoneValue?.value = '+$countryDial$local';
//       }
//     }
//   }
//
//   final String? initialPhoneNumber;
//   String? _initialCountryDialCode;
//
//   final Function(Country)? onCountryChanged;
//   final TextEditingController controller;
//   final String? hintText;
//   final String labelText;
//   final FutureOr<String?> Function(PhoneNumber?)? validator;
//   final void Function(PhoneNumber)? onChanged;
//   final Widget? prefixIcon;
//   final Widget? suffixIcon;
//   final FocusNode? focusNode;
//   final Color? fillColor;
//   final bool readOnly;
//   final bool obscureText;
//   final double? height;
//   final double? width;
//   final double borderRadius;
//   final double borderWidth;
//   final TextInputType? keyboardType;
//   final TextAlign? textAlign;
//   final TextStyle? hintStyle;
//   final TextStyle? style;
//   final EdgeInsetsGeometry? contentPadding;
//   final bool isMargin;
//   final bool enabled;
//   final String? invalidNumberMessage;
//   final String initialCountryCode;
//   final ValueNotifier<String>? internationalPhoneValue;
//   final TextInputAction? textInputAction;
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final baseDecoration = const InputDecoration().applyDefaults(
//       theme.inputDecorationTheme,
//     );
//
//     void _updateIntlByParts({required String countryCodeWithPlus}) {
//       if (internationalPhoneValue == null) return;
//       String raw = controller.text.trim().replaceAll(RegExp(r'\D'), '');
//       if (raw.startsWith('0')) raw = raw.substring(1);
//       internationalPhoneValue!.value = '$countryCodeWithPlus$raw';
//     }
//
//     return Directionality(
//       textDirection: TextDirection.ltr,
//       child: MyCustomIntlField(
//         textInputAction: textInputAction,
//         initialCountryCode: _initialCountryDialCode != null
//             ? _countryCodeFromDial(_initialCountryDialCode!) ??
//                   initialCountryCode
//             : initialCountryCode,
//         controller: controller,
//         enabled: enabled,
//         focusNode: focusNode,
//         readOnly: readOnly,
//         invalidNumberMessage: invalidNumberMessage,
//         onCountryChanged: (country) {
//           _updateIntlByParts(countryCodeWithPlus: '+${country.dialCode}');
//           onCountryChanged?.call(country);
//         },
//         onChanged: (phone) {
//           if (internationalPhoneValue != null) {
//             String raw = phone.number.replaceAll(RegExp(r'\D'), '');
//             if (raw.startsWith('0')) raw = raw.substring(1);
//             internationalPhoneValue!.value = '${phone.countryCode}$raw';
//           }
//           onChanged?.call(phone);
//         },
//         validator: validator,
//         keyboardType: keyboardType ?? TextInputType.phone,
//         textAlign: textAlign ?? TextAlign.start,
//         style: context.headlineSmall(
//           color: context.themeExt.palette.black,
//           fontSize: 16,
//         ),
//         decoration: baseDecoration.copyWith(
//           labelText: labelText,
//           filled: true,
//           fillColor: fillColor ?? context.onSecondaryColor,
//           hintText: hintText,
//           hintStyle:
//               hintStyle ??
//               context.headlineSmall(
//                 color: context.textFieldHintColor,
//                 fontSize: 16,
//               ),
//           prefixIcon: prefixIcon,
//           suffixIcon: suffixIcon,
//           contentPadding: contentPadding ?? const EdgeInsets.all(18),
//         ),
//       ),
//     );
//   }
//
//   /// يحاول إيجاد كود الدولة من رقم الطلب الدولي
//   String? _countryCodeFromDial(String dial) {
//     final allCountries = countries; // من مكتبة intl_phone_field
//     final found = allCountries.firstWhere(
//       (c) => c.dialCode == dial,
//       orElse: () => Country(
//         name: '',
//         code: '',
//         dialCode: '',
//         flag: '',
//         maxLength: 0,
//         minLength: 0,
//         nameTranslations: {},
//       ),
//     );
//     return found.code.isNotEmpty ? found.code : null;
//   }
// }
