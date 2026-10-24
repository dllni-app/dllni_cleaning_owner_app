import 'package:flutter/material.dart';
import 'tokens.dart';

enum WrActionRole { primary, secondary, destructive }

/// Busy and disabled states suppress callbacks. Explanation is caller-safe copy.
class WrActionButton extends StatelessWidget {
  const WrActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.role = WrActionRole.primary,
    this.busy = false,
    this.busyLabel,
    this.disabledExplanation,
    this.leadingIcon,
    this.expand = true,
  }) : assert(
         !busy || busyLabel != null,
         'Supply a caller-localized busyLabel for busy actions',
       );
  final String label;
  final VoidCallback? onPressed;
  final WrActionRole role;
  final bool busy;

  /// Caller-localized progress description; required when [busy] is true.
  final String? busyLabel;
  final String? disabledExplanation;
  final IconData? leadingIcon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final (background, foreground, border) = switch (role) {
      WrActionRole.primary => (WrColors.navy, Colors.white, WrColors.navy),
      WrActionRole.secondary => (
        WrColors.surfaceAlt,
        WrColors.navy,
        WrColors.border,
      ),
      WrActionRole.destructive => (
        WrColors.dangerBg,
        WrColors.danger,
        WrColors.danger,
      ),
    };
    final button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      value: busy ? busyLabel : null,
      liveRegion: busy,
      hint: enabled || busy ? null : disabledExplanation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
        child: Material(
          color: enabled ? background : WrColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WrRadius.control),
            side: BorderSide(color: enabled ? border : WrColors.border),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(WrRadius.control),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: WrSpace.md,
                vertical: WrSpace.sm,
              ),
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    ExcludeSemantics(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: WrColors.secondaryInk,
                        ),
                      ),
                    )
                  else if (leadingIcon != null)
                    Icon(
                      leadingIcon,
                      size: 18,
                      color: enabled ? foreground : WrColors.secondaryInk,
                    ),
                  if (busy || leadingIcon != null)
                    const SizedBox(width: WrSpace.xs),
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        style: WrType.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: enabled ? foreground : WrColors.secondaryInk,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class WrIconAction extends StatelessWidget {
  const WrIconAction({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.busyLabel,
  }) : assert(
         !busy || busyLabel != null,
         'Supply a caller-localized busyLabel for busy icon actions',
       );
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  /// Caller-localized progress description; required when [busy] is true.
  final String? busyLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null && !busy,
    label: label,
    value: busy ? busyLabel : null,
    liveRegion: busy,
    child: IconButton(
      tooltip: null,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const ExcludeSemantics(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Icon(icon),
    ),
  );
}
