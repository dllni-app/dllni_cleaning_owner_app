import 'dart:async';
import 'package:common_package/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/helpers.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart' hide PhoneNumber;

import '../../../generated/assets.dart';



class MyCustomIntlField extends StatefulWidget {
  final bool obscureText;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final VoidCallback? onTap;
  final bool readOnly;
  final FormFieldSetter<PhoneNumber>? onSaved;
  final ValueChanged<PhoneNumber>? onChanged;
  final ValueChanged<Country>? onCountryChanged;
  final FutureOr<String?> Function(PhoneNumber?)? validator;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  // final FocusNode? nextFocusNode;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final Brightness? keyboardAppearance;
  final String? initialValue;
  final String languageCode;
  final String? initialCountryCode;
  final List<Country>? countries;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool disableLengthCheck;
  final bool showDropdownIcon;
  final BoxDecoration dropdownDecoration;
  final TextStyle? dropdownTextStyle;
  final List<TextInputFormatter>? inputFormatters;

  final IconPosition dropdownIconPosition;
  final Icon dropdownIcon;
  final bool autofocus;
  final AutovalidateMode? autovalidateMode;
  final bool showCountryFlag;
  final String? invalidNumberMessage;
  final Color? cursorColor;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final double cursorWidth;
  final bool? showCursor;
  final EdgeInsetsGeometry flagsButtonPadding;
  final TextInputAction? textInputAction;
  final PickerDialogStyle? pickerDialogStyle;
  final EdgeInsets flagsButtonMargin;
  final bool disableAutoFillHints;

  MyCustomIntlField({
    Key? key,
    this.initialCountryCode,
    // this.nextFocusNode,
    this.languageCode = 'en',
    this.disableAutoFillHints = false,
    this.obscureText = false,
    this.textAlign = TextAlign.left,
    this.textAlignVertical,
    this.onTap,
    this.readOnly = false,
    this.initialValue,
    this.keyboardType = TextInputType.phone,
    this.controller,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.style,
    this.dropdownTextStyle,
    this.onSubmitted,
    this.validator,
    this.onChanged,
    this.countries,
    this.onCountryChanged,
    this.onSaved,
    this.showDropdownIcon = true,
    this.dropdownDecoration = const BoxDecoration(),
    this.inputFormatters,
    this.enabled = true,
    this.keyboardAppearance,
    @Deprecated('Use searchFieldInputDecoration of PickerDialogStyle instead')
    this.dropdownIconPosition = IconPosition.leading,
    this.dropdownIcon = const Icon(Icons.arrow_drop_down),
    this.autofocus = false,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.showCountryFlag = true,
    this.cursorColor,
    this.disableLengthCheck = false,
    this.flagsButtonPadding = EdgeInsets.zero,
    this.invalidNumberMessage = 'Invalid Mobile Number',
    this.cursorHeight,
    this.cursorRadius = Radius.zero,
    this.cursorWidth = 2.0,
    this.showCursor = true,
    this.pickerDialogStyle,
    this.flagsButtonMargin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  _IntlPhoneFieldState createState() => _IntlPhoneFieldState();
}

class _IntlPhoneFieldState extends State<MyCustomIntlField> {
  late List<Country> _countryList;
  late Country _selectedCountry;
  late List<Country> filteredCountries;
  late String number;

  String? validatorMessage;

  @override
  void initState() {
    super.initState();

    _countryList = (widget.countries ?? countries).map((country) {
      if (country.code == 'SY') {
        // عدل علم سوريا ليكون مسار صورة وليس emoji
        return Country(
          name: country.name,
          flag: 'assets/images/syria_flag_icon.svg',
          // مسار صورة علم سوريا
          code: country.code,
          dialCode: country.dialCode,
          minLength: 9,
          maxLength: 9,
          regionCode: country.regionCode,
          nameTranslations: country.nameTranslations,
        );
      }
      return country;
    }).toList();
    filteredCountries = _countryList;
    number = widget.initialValue ?? '';

    if (widget.initialCountryCode == null && number.startsWith('+')) {
      number = number.substring(1);
      _selectedCountry = _countryList.firstWhere(
            (country) => number.startsWith(country.fullCountryCode),
        orElse: () => _countryList.first,
      );
      number = number.replaceFirst(
        RegExp("^${_selectedCountry.fullCountryCode}"),
        "",
      );
    } else {
      _selectedCountry = _countryList.firstWhere(
            (item) => item.code == (widget.initialCountryCode ?? 'US'),
        orElse: () => _countryList.first,
      );

      if (number.startsWith('+')) {
        number = number.replaceFirst(
          RegExp("^\\+${_selectedCountry.fullCountryCode}"),
          "",
        );
      } else {
        number = number.replaceFirst(
          RegExp("^${_selectedCountry.fullCountryCode}"),
          "",
        );
      }
    }

    if (widget.autovalidateMode == AutovalidateMode.always) {
      final initialPhoneNumber = PhoneNumber(
        countryISOCode: _selectedCountry.code,
        countryCode: '+${_selectedCountry.dialCode}',
        number: widget.initialValue ?? '',
      );

      final value = widget.validator?.call(initialPhoneNumber);

      if (value is String) {
        validatorMessage = value;
      } else {
        (value as Future).then((msg) {
          validatorMessage = msg;
        });
      }
    }
  }

  Future<void> _changeCountry() async {
    filteredCountries = _countryList;
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => CountryPickerDialog(
          languageCode: context.locale.languageCode,
          style: widget.pickerDialogStyle,
          filteredCountries: filteredCountries,
          countryList: _countryList,
          selectedCountry: _selectedCountry,
          onCountryChanged: (Country country) {
            _selectedCountry = country;
            widget.onCountryChanged?.call(country);
            setState(() {});
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }
  Widget _buildFlagsButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffE5E7EB),
          width: 1,
        ),
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

            if (widget.showCountryFlag) ...[
              _buildFlagWidget(_selectedCountry),
              const SizedBox(width: 8),
            ],

            FittedBox(
              child: Text(
                '+${_selectedCountry.dialCode}',
                style: const TextStyle(
                  color: Color(0xff2F2B3D),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  // دالة لفحص هل العلم مسار صورة أم emoji
  bool _isAssetPath(String flag) {
    return flag.contains('assets/') ||
        flag.endsWith('.png') ||
        flag.endsWith('.jpg');
  }

  Widget _buildFlagWidget(Country country) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
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

  // Widget _buildFlagWidget(Country country) {
  //   if (_isAssetPath(country.flag)) {
  //     if (country.flag.endsWith('.svg')) {
  //       return SvgAsset(

  //         country.flag,
  //         width: 32,
  //         height: 20,
  //       );
  //     } else {
  //       return Image.asset(
  //         country.flag,
  //         package: kIsWeb ? 'intl_phone_field' : null,
  //         width: 32,
  //         height: 20,
  //         fit: BoxFit.cover,
  //         errorBuilder: (context, error, stackTrace) {
  //           return const Icon(Icons.flag);
  //         },
  //       );
  //     }
  //   } else {
  //     return Text(country.flag, style: const TextStyle(fontSize: 18));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:kMinInteractiveDimension+24 ,

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildFlagsButton()),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: SizedBox.expand(
              child: SizedBox(


                child: TextFormField(
                  expands: true,
                  minLines:null,
                  maxLines:null,


                  initialValue: (widget.controller == null) ? number : null,
                  autofillHints: widget.disableAutoFillHints
                      ? null
                      : [AutofillHints.telephoneNumberNational],
                  readOnly: widget.readOnly,
                  obscureText: widget.obscureText,
                  textAlign: widget.textAlign,
                  textAlignVertical: widget.textAlignVertical,
                  cursorColor: widget.cursorColor,
                  onTap: widget.onTap,
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  cursorHeight: widget.cursorHeight,
                  cursorRadius: widget.cursorRadius,
                  cursorWidth: widget.cursorWidth,
                  showCursor: widget.showCursor,
                  onFieldSubmitted: widget.onSubmitted,


                  decoration: widget.decoration.copyWith(

                    fillColor: Colors.white,
                    counterText: !widget.enabled ? '' : null,
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12
                    ),
                  ),
                  style: widget.style,
                  onSaved: (value) {
                    widget.onSaved?.call(
                      PhoneNumber(
                        countryISOCode: _selectedCountry.code,
                        countryCode:
                        '+${_selectedCountry.dialCode}${_selectedCountry.regionCode}',
                        number: value!,
                      ),
                    );
                  },
                  onChanged: (value) async {
                    final phoneNumber = PhoneNumber(
                      countryISOCode: _selectedCountry.code,
                      countryCode: '+${_selectedCountry.fullCountryCode}',
                      number: value,
                    );

                    if (widget.autovalidateMode != AutovalidateMode.disabled) {
                      validatorMessage = await widget.validator?.call(phoneNumber);
                    }

                    widget.onChanged?.call(phoneNumber);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty || !isNumeric(value)) {
                      return 'هذا الحقل مطلوب';
                    }

                    if (!widget.disableLengthCheck) {
                      return value.length >= _selectedCountry.minLength &&
                          value.length <= _selectedCountry.maxLength
                          ? null
                          : 'رقم الهاتف غير صحيح';
                    }

                    return validatorMessage;
                  },
                  maxLength: widget.disableLengthCheck ? null : _selectedCountry.maxLength,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  enabled: widget.enabled,
                  keyboardAppearance: widget.keyboardAppearance,
                  autofocus: widget.autofocus,
                  textInputAction: widget.textInputAction,
                  autovalidateMode: widget.autovalidateMode,

                ),
              ),
            ),
          ),

        ],
      ),
    );
  }



}

enum IconPosition { leading, trailing }

// تعديل اسم الكلاس ليطابق الاصل مع الاستخدام الصحيح للـ PickerDialogStyle
class PickerDialogStyle {
  final Color? backgroundColor;
  final TextStyle? countryCodeStyle;
  final TextStyle? countryNameStyle;
  final Widget? listTileDivider;
  final EdgeInsets? listTilePadding;
  final EdgeInsets? padding;
  final Color? searchFieldCursorColor;
  final InputDecoration? searchFieldInputDecoration;
  final EdgeInsets? searchFieldPadding;
  final double? width;

  PickerDialogStyle({
    this.backgroundColor,
    this.countryCodeStyle,
    this.countryNameStyle,
    this.listTileDivider,
    this.listTilePadding,
    this.padding,
    this.searchFieldCursorColor,
    this.searchFieldInputDecoration,
    this.searchFieldPadding,
    this.width,
  });
}

class CountryPickerDialog extends StatefulWidget {
  final List<Country> countryList;
  final Country selectedCountry;
  final ValueChanged<Country> onCountryChanged;
  final List<Country> filteredCountries;
  final PickerDialogStyle? style;
  final String languageCode;

  const CountryPickerDialog({
    Key? key,
    required this.languageCode,
    required this.countryList,
    required this.onCountryChanged,
    required this.selectedCountry,
    required this.filteredCountries,
    this.style,
  }) : super(key: key);

  @override
  _CountryPickerDialogState createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<CountryPickerDialog> {
  late List<Country> _filteredCountries;
  late Country _selectedCountry;

  @override
  void initState() {
    _selectedCountry = widget.selectedCountry;
    _filteredCountries = widget.filteredCountries.toList()
      ..sort(
            (a, b) => a
            .localizedName(widget.languageCode)
            .compareTo(b.localizedName(widget.languageCode)),
      );

    super.initState();
  }

  bool _isAssetPath(String flag) {
    return flag.contains('assets/') ||
        flag.endsWith('.svg') ||
        flag.endsWith('.jpg');
  }

  Widget _buildFlagWidget(Country country) {
    if (_isAssetPath(country.flag)) {
      return SvgAsset(
        country.flag,
        width: 25,



      );
    } else {
      return Text(country.flag, style: const TextStyle(fontSize: 18));
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final width = widget.style?.width ?? mediaWidth;
    const defaultHorizontalPadding = 40.0;
    const defaultVerticalPadding = 24.0;
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        vertical: defaultVerticalPadding,
        horizontal: mediaWidth > (width + defaultHorizontalPadding * 2)
            ? (mediaWidth - width) / 2
            : defaultHorizontalPadding,
      ),
      backgroundColor: widget.style?.backgroundColor,
      child: Container(
        padding: widget.style?.padding ?? const EdgeInsets.symmetric(vertical:  20,horizontal: 10),
        child: Column(
          children: [
            TextField(
              maxLines: 1, // يخلي النص يتمدد داخله

              cursorColor: widget.style?.searchFieldCursorColor,
              style: const TextStyle(
                color: Color(0xff2F2B3D),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),

              decoration:
              InputDecoration(
          filled: true,
          fillColor: const Color(0xffF9FAFB),

          suffixIcon: const Icon(
            Icons.search,
            color: Color(0xff6B7280),
          ),

          labelText: 'ابحث عن الدولة',

          labelStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),

          floatingLabelStyle: const TextStyle(
            color: Color(0xff1E2A78),
            fontSize: 12,
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xffE5E7EB),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xffE5E7EB),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xff1E2A78),
              width: 1.2,
            ),
          ),
        ),
              onChanged: (value) {
                _filteredCountries = widget.countryList.stringSearch(value)
                  ..sort(
                        (a, b) => a
                        .localizedName(widget.languageCode)
                        .compareTo(b.localizedName(widget.languageCode)),
                  );
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCountries.length,
                itemBuilder: (ctx, index) => Column(
                  children: <Widget>[
                    ListTile(
                      leading: _buildFlagWidget(_filteredCountries[index]),
                      contentPadding: widget.style?.listTilePadding,
                      title: Text(
                        _filteredCountries[index].localizedName(
                          widget.languageCode,
                        ),
                        style: const TextStyle(
                          color: Color(0xff2F2B3D),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      trailing: Text(
                        '+${_filteredCountries[index].dialCode}',
                        style: const TextStyle(
                          color: Color(0xff2F2B3D),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      onTap: () {
                        _selectedCountry = _filteredCountries[index];
                        widget.onCountryChanged(_selectedCountry);
                        Navigator.of(context).pop();
                      },
                    ),
                    widget.style?.listTileDivider ??
                        const  Divider(
                      thickness: 1,
                      color: Color(0xffE5E7EB),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class SvgAsset extends StatelessWidget {
  const SvgAsset(
      this.assetName, {
        super.key,
        this.color,
        this.width = 25,
        this.height = 25,

      });
  final Color? color;
  final double width;
  final double height;

  final String assetName;
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      color: color,
      width: width,
      height: height,
      fit: BoxFit.contain,


    );
  }
}

