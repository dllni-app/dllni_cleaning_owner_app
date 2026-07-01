import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

class MissionFinishButton extends StatelessWidget {
  const MissionFinishButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.text,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff1DBCC8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : AppText.labelLarge(
              text,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
    );
  }
}
