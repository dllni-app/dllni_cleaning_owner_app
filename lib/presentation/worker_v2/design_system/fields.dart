import 'package:flutter/material.dart';
import 'tokens.dart';

/// Platform text field with permanently visible label and caller-supplied error.
class WrField extends StatelessWidget {
  const WrField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.inputDirection,
    this.enabled = true,
    this.obscureText = false,
    this.suffixIcon,
  });
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextDirection? inputDirection;
  final bool enabled;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textDirection: inputDirection,
        onChanged: onChanged,
        decoration: InputDecoration(
          // The visible label belongs to the input's own decoration semantics.
          // It stays visible even when there is no hint or the field is empty.
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          floatingLabelStyle: WrType.support.copyWith(
            fontWeight: FontWeight.w700,
          ),
          hintText: hint,
          errorText: errorText,
          suffixIcon: suffixIcon,
          errorMaxLines: 4,
        ),
      ),
    ],
  );
}

class WrPhoneField extends StatelessWidget {
  const WrPhoneField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;
  @override
  Widget build(BuildContext context) => WrField(
    label: label,
    controller: controller,
    onChanged: onChanged,
    hint: hint,
    errorText: errorText,
    enabled: enabled,
    keyboardType: TextInputType.phone,
    inputDirection: TextDirection.ltr,
  );
}

class WrTimeField extends StatelessWidget {
  const WrTimeField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;
  @override
  Widget build(BuildContext context) => WrField(
    label: label,
    controller: controller,
    onChanged: onChanged,
    hint: hint,
    errorText: errorText,
    enabled: enabled,
    keyboardType: TextInputType.datetime,
    inputDirection: TextDirection.ltr,
  );
}

class WrPasswordField extends StatefulWidget {
  const WrPasswordField({
    super.key,
    required this.label,
    required this.revealLabel,
    required this.hideLabel,
    this.controller,
    this.onChanged,
    this.hint,
    this.errorText,
    this.enabled = true,
  });
  final String label;
  final String revealLabel;
  final String hideLabel;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? errorText;
  final bool enabled;
  @override
  State<WrPasswordField> createState() => _WrPasswordFieldState();
}

class _WrPasswordFieldState extends State<WrPasswordField> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) => WrField(
    label: widget.label,
    controller: widget.controller,
    hint: widget.hint,
    errorText: widget.errorText,
    enabled: widget.enabled,
    onChanged: widget.onChanged,
    obscureText: !_visible,
    suffixIcon: IconButton(
      tooltip: _visible ? widget.hideLabel : widget.revealLabel,
      onPressed: widget.enabled
          ? () => setState(() => _visible = !_visible)
          : null,
      icon: Icon(
        _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
    ),
  );
}
