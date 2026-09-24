import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../../core/theme/worker_app_colors.dart';

class MainPersistentBottomNavBar extends StatelessWidget {
  const MainPersistentBottomNavBar({
    super.key,
    required this.controller,
    required this.onItemSelected,
    required this.onSupportTap,
  });

  final PersistentTabController controller;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onSupportTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedIndex = controller.index;
        return Container(
          color: WorkerAppColors.canvas,
          padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 12),
          child: Container(
            height: 70,
            padding: const EdgeInsetsDirectional.all(5),
            decoration: BoxDecoration(
              color: WorkerAppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: WorkerAppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x120F172A),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _NavItem(
                  label: 'الرئيسية',
                  icon: Icons.home_rounded,
                  selected: selectedIndex == 0,
                  onTap: () => onItemSelected(0),
                ),
                _NavItem(
                  label: 'تقويمي',
                  icon: Icons.calendar_month_rounded,
                  selected: selectedIndex == 1,
                  onTap: () => onItemSelected(1),
                ),
                _NavItem(
                  label: 'الدعم',
                  icon: Icons.headset_mic_rounded,
                  selected: false,
                  danger: true,
                  onTap: onSupportTap,
                ),
                _NavItem(
                  label: 'الطلبات',
                  icon: Icons.assignment_rounded,
                  selected: selectedIndex == 2,
                  onTap: () => onItemSelected(2),
                ),
                _NavItem(
                  label: 'المزيد',
                  icon: Icons.person_rounded,
                  selected: selectedIndex == 3,
                  onTap: () => onItemSelected(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = danger
        ? WorkerAppColors.danger
        : selected
        ? WorkerAppColors.brandPrimary
        : WorkerAppColors.textSecondary;
    final background = danger
        ? WorkerAppColors.dangerSoft
        : selected
        ? WorkerAppColors.brandPrimarySoft
        : Colors.transparent;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(17),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foreground, size: 21),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: selected || danger
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
