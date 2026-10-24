import 'package:flutter/material.dart';
import 'tokens.dart';
import 'actions.dart';

enum WrStatusTone { neutral, success, warning, danger, info }

(Color, Color) _toneColors(WrStatusTone tone) => switch (tone) {
  WrStatusTone.neutral => (WrColors.surfaceAlt, WrColors.secondaryInk),
  WrStatusTone.success => (WrColors.successBg, WrColors.success),
  WrStatusTone.warning => (WrColors.warningBg, WrColors.warning),
  WrStatusTone.danger => (WrColors.dangerBg, WrColors.danger),
  WrStatusTone.info => (WrColors.infoBg, WrColors.info),
};

/// Localized, caller-approved text and an optional icon express the full state.
class WrStatusBadge extends StatelessWidget {
  const WrStatusBadge({
    super.key,
    required this.label,
    this.tone = WrStatusTone.neutral,
    this.icon,
  });
  final String label;
  final WrStatusTone tone;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _toneColors(tone);
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(WrRadius.control),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: WrSpace.sm,
            vertical: WrSpace.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: WrSpace.xxs),
              ],
              Flexible(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    softWrap: true,
                    style: WrType.support.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WrEligibilityNotice extends StatelessWidget {
  const WrEligibilityNotice({
    super.key,
    required this.title,
    required this.message,
    this.tone = WrStatusTone.warning,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final WrStatusTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _toneColors(tone);
    return Container(
      padding: const EdgeInsets.all(WrSpace.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(WrRadius.panel),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: WrType.section.copyWith(color: foreground)),
          Text(message, style: WrType.support.copyWith(color: foreground)),
          if (actionLabel != null) ...[
            const SizedBox(height: WrSpace.sm),
            WrActionButton(
              label: actionLabel!,
              onPressed: onAction,
              role: WrActionRole.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

enum WrFeedbackKind {
  loading,
  empty,
  initialError,
  refreshError,
  forbidden,
  unavailable,
  offline,
}

/// Never treats empty/zero values as loading or invents retained content.
class WrFeedbackPanel extends StatelessWidget {
  const WrFeedbackPanel({
    super.key,
    required this.kind,
    required this.title,
    this.message,
    this.retainedContent,
    this.retryLabel,
    this.onRetry,
  });
  final WrFeedbackKind kind;
  final String title;
  final String? message;
  final Widget? retainedContent;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final showRetained =
        kind == WrFeedbackKind.refreshError && retainedContent != null;
    final marker = kind == WrFeedbackKind.loading
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(switch (kind) {
            WrFeedbackKind.empty => Icons.inbox_outlined,
            WrFeedbackKind.forbidden => Icons.lock_outline,
            WrFeedbackKind.offline => Icons.wifi_off_outlined,
            WrFeedbackKind.unavailable => Icons.event_busy_outlined,
            _ => Icons.info_outline,
          }, color: WrColors.secondaryInk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showRetained) ...[
          retainedContent!,
          const SizedBox(height: WrSpace.sm),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: WrColors.surfaceAlt,
            borderRadius: BorderRadius.circular(WrRadius.panel),
            border: Border.all(color: WrColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(WrSpace.md),
            child: Column(
              children: [
                marker,
                const SizedBox(height: WrSpace.xs),
                Text(title, style: WrType.section, textAlign: TextAlign.center),
                if (message != null)
                  Text(
                    message!,
                    style: WrType.support,
                    textAlign: TextAlign.center,
                  ),
                if (onRetry != null && retryLabel != null) ...[
                  const SizedBox(height: WrSpace.sm),
                  WrActionButton(
                    label: retryLabel!,
                    onPressed: onRetry,
                    role: WrActionRole.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
