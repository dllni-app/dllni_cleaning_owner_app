import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../helpers/phone_number_helper.dart';

enum AppPhoneFieldVariant { ownerLogin, ownerProfile }

class AppPhoneNumberField extends StatefulWidget {
  const AppPhoneNumberField({
    super.key,
    this.label,
    this.isRequired = false,
    this.hintText = 'أدخل رقم الجوال',
    this.initialValue,
    this.onChanged,
    this.enabled = true,
    this.variant = AppPhoneFieldVariant.ownerProfile,
    this.showLabel = true,
    this.validator,
  });

  final String? label;
  final bool isRequired;
  final String hintText;
  final PhoneNumber? initialValue;
  final ValueChanged<PhoneNumber>? onChanged;
  final bool enabled;
  final AppPhoneFieldVariant variant;
  final bool showLabel;
  final Future<String?> Function(PhoneNumber?)? validator;

  @override
  State<AppPhoneNumberField> createState() => AppPhoneNumberFieldState();
}

class AppPhoneNumberFieldState extends State<AppPhoneNumberField> {
  PhoneNumber? _phone;

  PhoneNumber? get phone => _phone;

  Future<String?> validate() async {
    if (widget.validator != null) {
      return widget.validator!(_phone);
    }
    return validatePhoneNumber(_phone);
  }

  @override
  void initState() {
    super.initState();
    _phone = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant AppPhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _phone = widget.initialValue;
    }
  }

  InputDecoration _decoration(BuildContext context) {
    final borderRadius = BorderRadius.circular(
      widget.variant == AppPhoneFieldVariant.ownerLogin ? 14.r : 14.r,
    );
    final fillColor = widget.variant == AppPhoneFieldVariant.ownerLogin
        ? context.onPrimary
        : const Color(0xffF9FAFB);
    final borderColor = widget.variant == AppPhoneFieldVariant.ownerLogin
        ? Colors.grey.shade300
        : const Color(0xffE5E7EB);

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: widget.variant == AppPhoneFieldVariant.ownerLogin
            ? 14
            : 14.sp,
      ),
      filled: true,
      fillColor: fillColor,
      contentPadding: EdgeInsets.symmetric(
        horizontal: widget.variant == AppPhoneFieldVariant.ownerLogin
            ? 16.w
            : 14.w,
        vertical: widget.variant == AppPhoneFieldVariant.ownerLogin
            ? 16.h
            : 12.h,
      ),
      prefixIcon: Icon(
        Icons.phone_outlined,
        color: Colors.grey.shade400,
        size: widget.variant == AppPhoneFieldVariant.ownerLogin ? 20 : 20.sp,
      ),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: widget.variant == AppPhoneFieldVariant.ownerLogin
              ? context.secondary
              : context.primary,
          width: widget.variant == AppPhoneFieldVariant.ownerLogin ? 1 : 1.1.w,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: context.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: context.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = Directionality(
      textDirection: TextDirection.ltr,
      child: InternationalPhoneNumberInput(
        initialValue: widget.initialValue ?? _phone,
        onInputChanged: (number) {
          _phone = number;
          widget.onChanged?.call(number);
        },
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DROPDOWN,
          showFlags: true,
          useEmoji: true,
          leadingPadding: 8,
          trailingSpace: false,
        ),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.disabled,
        formatInput: true,
        keyboardType: TextInputType.phone,
        textAlign: TextAlign.left,
        inputDecoration: _decoration(context),
        selectorTextStyle: TextStyle(
          color: const Color(0xff2F2B3D),
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        textStyle: TextStyle(
          color: const Color(0xff2F2B3D),
          fontSize: widget.variant == AppPhoneFieldVariant.ownerLogin
              ? 14
              : 14.sp,
          fontWeight: FontWeight.w400,
        ),
        countries: const [defaultPhoneIsoCode],
        validator: (value) => validatePhoneNumberText(value),
        isEnabled: widget.enabled,
        locale: 'ar',
      ),
    );

    final field = widget.enabled ? input : AbsorbPointer(child: input);

    if (!widget.showLabel || widget.label == null) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppText.bodyMedium(
              widget.label!,
              fontWeight: widget.variant == AppPhoneFieldVariant.ownerLogin
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: widget.variant == AppPhoneFieldVariant.ownerLogin
                  ? const Color(0xff111827)
                  : null,
            ),
            if (widget.isRequired)
              AppText.bodyMedium(
                '*',
                color: context.error,
                fontWeight: FontWeight.w500,
              ),
          ],
        ),
        SizedBox(height: 8.h),
        field,
      ],
    );
  }
}
