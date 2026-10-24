import 'package:flutter/material.dart';
import 'tokens.dart';
import 'actions.dart';

/// Content container for caller-owned modal bottom sheets; insets follow the IME.
class WrSheetFrame extends StatelessWidget {
  const WrSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.submitting = false,
    this.submittingLabel,
  }) : assert(
         !submitting || submittingLabel != null,
         'Supply a caller-localized submittingLabel',
       );
  final String title;
  final Widget child;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool submitting;

  /// Caller-localized progress text for the primary action when submitting.
  final String? submittingLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: WrColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(WrRadius.sheet),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(WrSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: WrType.section),
                  const SizedBox(height: WrSpace.md),
                  child,
                  if (primaryLabel != null) ...[
                    const SizedBox(height: WrSpace.lg),
                    WrActionButton(
                      label: primaryLabel!,
                      onPressed: onPrimary,
                      busy: submitting,
                      busyLabel: submittingLabel,
                    ),
                  ],
                  if (secondaryLabel != null) ...[
                    const SizedBox(height: WrSpace.xs),
                    WrActionButton(
                      label: secondaryLabel!,
                      onPressed: submitting ? null : onSecondary,
                      role: WrActionRole.secondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caller owns approval policy and the decision to dismiss this dialog.
class WrConfirmDialog extends StatelessWidget {
  const WrConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.busy = false,
    this.busyLabel,
    this.destructive = false,
  }) : assert(
         !busy || busyLabel != null,
         'Supply a caller-localized busyLabel for dialog confirmation',
       );
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool busy;

  /// Caller-localized progress description while confirmation is pending.
  final String? busyLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title, style: WrType.section),
    content: SingleChildScrollView(child: Text(message, style: WrType.body)),
    actions: [
      WrActionButton(
        label: cancelLabel,
        expand: false,
        role: WrActionRole.secondary,
        onPressed: busy ? null : onCancel,
      ),
      WrActionButton(
        label: confirmLabel,
        expand: false,
        role: destructive ? WrActionRole.destructive : WrActionRole.primary,
        onPressed: onConfirm,
        busy: busy,
        busyLabel: busyLabel,
      ),
    ],
  );
}
