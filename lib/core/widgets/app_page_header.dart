import 'package:flutter/material.dart';

import '../theme/app_layout.dart';

class AppPageHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
    this.showBackButton = true,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBackButton;
  final Widget? leading;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 72 : 88);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppBar(
      automaticallyImplyLeading: showBackButton,
      leading: leading,
      actions: actions,
      toolbarHeight: preferredSize.height,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpace.xxs),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ],
      ),
      shape: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
    );
  }
}
