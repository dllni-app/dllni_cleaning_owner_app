import 'package:flutter/material.dart';

import '../helpers/worker_order_visual_identity.dart';

/// Compact, wrapping Arabic labels shared by the home/orders and calendar cards.
class WorkerOrderIdentityChips extends StatelessWidget {
  const WorkerOrderIdentityChips({
    super.key,
    required this.identity,
    this.isPreferredForMe = false,
  });

  final WorkerOrderVisualIdentity identity;
  final bool isPreferredForMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    return Wrap(
      key: const Key('worker-order-identity-chips'),
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(identity.family, Icons.category_outlined, theme.primary),
        if (identity.isSupervised)
          _chip('فريق بإدارة مشرف', Icons.groups_outlined, theme.tertiary),
        if (isPreferredForMe)
          _chip('محدد لك', Icons.person_pin_circle_outlined, theme.error),
        if (identity.isSameDayRequest)
          _chip('طلب ساخن', Icons.bolt_outlined, theme.error),
      ],
    );
  }

  Widget _chip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
        color: color.withAlpha(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
