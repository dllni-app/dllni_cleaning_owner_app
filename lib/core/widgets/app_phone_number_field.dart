import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../helpers/phone_number_helper.dart';

enum AppPhoneFieldVariant { auth, profile }

class AppPhoneNumberField extends StatefulWidget {
  final String? label;

  final bool isRequired;
  final String hintText;
  final PhoneNumber? initialValue;
  final ValueChanged<PhoneNumber>? onChanged;
  final bool enabled;
  final AppPhoneFieldVariant variant;
  final bool showLabel;
  final Future<String?> Function(PhoneNumber?)? validator;
  const AppPhoneNumberField({
    super.key,
    this.label,
    this.isRequired = false,
    this.hintText = 'أدخل رقم الجوال',
    this.initialValue,
    this.onChanged,
    this.enabled = true,
    this.variant = AppPhoneFieldVariant.profile,
    this.showLabel = true,
    this.validator,
  });

  @override
  State<AppPhoneNumberField> createState() => AppPhoneNumberFieldState();
}

class AppPhoneNumberFieldState extends State<AppPhoneNumberField> {
  PhoneNumber? _phone;

  PhoneNumber? get phone => _phone;

  @override
  Widget build(BuildContext context) {
    final input = Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: _decoration(context),
            initialValue: _phone?.phoneNumber,
            onChanged: (value) {
              setState(() {
                _phone = PhoneNumber(phoneNumber: "+963$value");
              });
            },
          ),
        ),
        SizedBox(width: 8),
        _buildFlagsButton(),
      ],
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
            AppText.bodyMedium(widget.label!, fontWeight: FontWeight.w500),
            if (widget.isRequired)
              AppText.bodyMedium(
                '*',
                color: context.error,
                fontWeight: FontWeight.w500,
              ),
          ],
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  @override
  void didUpdateWidget(covariant AppPhoneNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      _phone = widget.initialValue;
    }
  }

  @override
  void initState() {
    super.initState();
    _phone = widget.initialValue;
  }

  Future<String?> validate() async {
    if (widget.validator != null) {
      return widget.validator!(_phone);
    }
    return validatePhoneNumber(_phone);
  }

  Widget _buildFlagsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE5E7EB), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // onTap: widget.enabled ? _changeCountry : null,
        onTap: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(width: 4),
            FittedBox(
              child: Text(
                '+963',
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  color: Color(0xff2F2B3D),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildFlagWidget(),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SvgPicture.asset(
          'assets/images/sy.svg',
          width: 28,
          height: 20,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context) {
    const borderColor = Color(0xffE5E7EB);
    const fillColor = Color(0xffF9FAFB);
    const iconGray = Color(0xff6B7280);

    if (widget.variant == AppPhoneFieldVariant.auth) {
      return InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        prefixIcon: const Icon(Icons.phone_rounded, color: iconGray, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.error, width: 1.2),
        ),
      );
    }

    return InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      prefixIcon: const Icon(
        Icons.phone_rounded,
        color: Color(0xff15803D),
        size: 22,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: context.error, width: 1.2),
      ),
    );
  }
}
