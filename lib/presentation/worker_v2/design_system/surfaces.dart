import 'package:flutter/material.dart';
import 'tokens.dart';

/// New screen scaffold with a scroll-safe body and a safe-area action dock.
class WrPageFrame extends StatelessWidget {
  const WrPageFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.headerAction,
    this.bottomAction,
  });
  final String title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget child;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final gutter = MediaQuery.sizeOf(context).width < 360
        ? WrSpace.md
        : WrSpace.lg;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  WrSpace.lg,
                  gutter,
                  WrSpace.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: WrType.page),
                              if (subtitle != null) ...[
                                const SizedBox(height: WrSpace.xs),
                                Text(subtitle!, style: WrType.support),
                              ],
                            ],
                          ),
                        ),
                        if (headerAction != null) headerAction!,
                      ],
                    ),
                    const SizedBox(height: WrSpace.xl),
                    child,
                  ],
                ),
              ),
            ),
            if (bottomAction != null)
              Container(
                width: double.infinity,
                padding: EdgeInsetsDirectional.fromSTEB(
                  gutter,
                  WrSpace.sm,
                  gutter,
                  WrSpace.md,
                ),
                decoration: const BoxDecoration(
                  color: WrColors.surface,
                  border: Border(top: BorderSide(color: WrColors.border)),
                ),
                child: bottomAction!,
              ),
          ],
        ),
      ),
    );
  }
}

class WrSectionPanel extends StatelessWidget {
  const WrSectionPanel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.action,
  });
  final String? title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WrColors.surface,
        border: Border.all(color: WrColors.border),
        borderRadius: BorderRadius.circular(WrRadius.panel),
      ),
      child: Padding(
        padding: const EdgeInsets.all(WrSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || action != null) ...[
              Row(
                children: [
                  if (title != null)
                    Expanded(child: Text(title!, style: WrType.section)),
                  if (action != null) action!,
                ],
              ),
            ],
            if (subtitle != null) Text(subtitle!, style: WrType.support),
            if (title != null || action != null || subtitle != null)
              const SizedBox(height: WrSpace.sm),
            child,
          ],
        ),
      ),
    );
  }
}
