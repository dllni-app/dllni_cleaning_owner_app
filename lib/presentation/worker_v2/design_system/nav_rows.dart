import 'package:flutter/material.dart';
import '../contracts/common.dart';
import 'tokens.dart';

/// Visual navigation item. The caller determines tab selection and route.
class WrNavigationItem extends StatelessWidget {
  const WrNavigationItem({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    enabled: onTap != null,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WrRadius.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.all(WrSpace.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? WrColors.navy : WrColors.secondaryInk,
              ),
              ExcludeSemantics(
                child: Text(
                  label,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: WrType.support.copyWith(
                    color: selected ? WrColors.navy : WrColors.secondaryInk,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WrListRow extends StatelessWidget {
  const WrListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleDirection,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;

  /// Explicit direction for mixed time/code spans (for example UTC in RTL).
  final TextDirection? subtitleDirection;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WrRadius.control),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: WrSpace.sm),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: WrSpace.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: WrType.body),
                    if (subtitle != null)
                      if (subtitleDirection == null)
                        Text(subtitle!, style: WrType.support)
                      else
                        Directionality(
                          textDirection: subtitleDirection!,
                          child: Text(subtitle!, style: WrType.support),
                        ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: WrSpace.xs),
                Flexible(child: trailing!),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Shows the exact amount given by the contract; null needs visible caller copy.
class WrAmountText extends StatelessWidget {
  const WrAmountText({
    super.key,
    required this.amount,
    required this.unavailableLabel,
  });
  final MoneyValue? amount;
  final String unavailableLabel;
  @override
  Widget build(BuildContext context) {
    if (amount == null) {
      return Text(unavailableLabel, style: WrType.support);
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        '${amount!.decimal} ${amount!.currency}',
        textAlign: TextAlign.start,
        style: WrType.body.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
