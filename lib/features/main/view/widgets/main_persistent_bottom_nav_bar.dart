import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../generated/assets.dart';

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
        return Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 12,
          shadowColor: Theme.of(
            context,
          ).colorScheme.shadow.withValues(alpha: 0.18),
          shape: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpace.xs,
              AppSpace.xs,
              AppSpace.xs,
              AppSpace.xs,
            ),
            child: Row(
              children: [
                _buildTabItem(
                  context: context,
                  tabIndex: 0,
                  selectedIndex: selectedIndex,
                  iconPath: Assets.images.navBarHome.path,
                  title: 'الرئيسية',
                  onTap: () => onItemSelected(0),
                ),
                _buildTabItem(
                  context: context,
                  tabIndex: 1,
                  selectedIndex: selectedIndex,
                  iconPath: Assets.images.navBarCalender.path,
                  title: 'تقويمي',
                  onTap: () => onItemSelected(1),
                ),
                _buildSupportItem(context),
                _buildTabItem(
                  context: context,
                  tabIndex: 2,
                  selectedIndex: selectedIndex,
                  iconPath: Assets.images.navBarOrders.path,
                  title: 'الطلبات',
                  onTap: () => onItemSelected(2),
                ),
                _buildTabItem(
                  context: context,
                  tabIndex: 3,
                  selectedIndex: selectedIndex,
                  iconPath: Assets.images.navBarMore.path,
                  title: 'المزيد',
                  onTap: () => onItemSelected(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportItem(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          label: 'الدعم الفني',
          child: InkWell(
            onTap: onSupportTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppGradients.hero,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.subtle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                    size: AppIconSize.lg,
                  ),
                ),
                const SizedBox(height: AppSpace.xxs),
                AppText.labelMedium(
                  'الدعم',
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required int tabIndex,
    required int selectedIndex,
    required String iconPath,
    required String title,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == tabIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isSelected ? colorScheme.secondary : colorScheme.outline;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          button: true,
          selected: isSelected,
          label: title,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: AppMotion.resolved(context, AppMotion.standard),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppSpace.xxs,
                vertical: AppSpace.xxs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.72)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 42,
                    height: 36,
                    child: AppImage.asset(
                      iconPath,
                      color: iconColor,
                      width: AppIconSize.md,
                      height: AppIconSize.md,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  AppText.labelMedium(
                    title,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: iconColor,
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
