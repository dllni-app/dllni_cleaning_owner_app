import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
import 'app_button.dart';

enum AppStateViewType { loading, empty, error }

class AppStateView extends StatelessWidget {
  const AppStateView.loading({super.key, this.message = 'جارٍ التحميل…'})
    : type = AppStateViewType.loading,
      onRetry = null,
      icon = null;

  const AppStateView.empty({
    super.key,
    this.message = 'لا توجد بيانات لعرضها الآن',
    this.icon = Icons.inbox_outlined,
    this.onRetry,
  }) : type = AppStateViewType.empty;

  const AppStateView.error({
    super.key,
    this.message = 'تعذّر تحميل البيانات. تحقق من اتصالك وحاول مجدداً.',
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : type = AppStateViewType.error;

  final AppStateViewType type;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoading = type == AppStateViewType.loading;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpace.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator.adaptive(),
                  )
                else
                  Icon(
                    icon,
                    size: 40,
                    color: type == AppStateViewType.error
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpace.md),
                  AppButton(
                    label: 'إعادة المحاولة',
                    onPressed: onRetry,
                    icon: Icons.refresh,
                    expand: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
