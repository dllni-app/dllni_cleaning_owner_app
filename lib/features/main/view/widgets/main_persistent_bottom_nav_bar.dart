import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

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

  static const _inactiveColor = Color(0xff526D6B);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final selectedIndex = controller.index;
        return Container(
          height: 84,
          decoration: BoxDecoration(
            color: context.onPrimary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(27),
                offset: const Offset(0, -2),
                blurRadius: 12,
              ),
            ],
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
        );
      },
    );
  }

  Widget _buildSupportItem(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onSupportTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: context.error.withAlpha(38),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: context.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              AppText.labelMedium(
                'الدعم',
                fontWeight: FontWeight.w300,
                color: context.error,
              ),
            ],
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
    final iconColor = isSelected ? context.primaryContainer : _inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isSelected
                    ? context.primaryContainer.withAlpha(63)
                    : Colors.transparent,
                child: AppImage.asset(
                  iconPath,
                  color: iconColor,
                  width: 28,
                  height: 28,
                ),
              ),
              const SizedBox(height: 6),
              AppText.labelMedium(
                title,
                fontWeight: FontWeight.w300,
                color: iconColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
