import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class WorkerTechnicalSupportCallOverlay extends StatelessWidget {
  const WorkerTechnicalSupportCallOverlay({
    super.key,
    required this.child,
    required this.visible,
    this.supportPhoneNumber = _defaultSupportPhoneNumber,
  });

  static const String _defaultSupportPhoneNumber = '+963000000000';

  final Widget child;
  final bool visible;
  final String supportPhoneNumber;

  Future<void> _callSupport(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: supportPhoneNumber);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppToast.showToast(
        context: context,
        message: 'تعذر فتح تطبيق الاتصال',
        type: ToastificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          PositionedDirectional(
            end: 16,
            bottom: 84 + MediaQuery.paddingOf(context).bottom,
            child: SafeArea(
              minimum: EdgeInsets.zero,
              child: Semantics(
                button: true,
                label: 'الاتصال بالدعم الفني',
                child: Tooltip(
                  message: 'الاتصال بالدعم الفني',
                  child: FloatingActionButton(
                    heroTag: 'worker_technical_support_call_fab',
                    onPressed: () => _callSupport(context),
                    backgroundColor: context.error,
                    foregroundColor: context.onError,
                    child: const Icon(Icons.support_agent_rounded),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class WorkerTechnicalSupportRouteObserver extends NavigatorObserver {
  WorkerTechnicalSupportRouteObserver({required this.onRouteChanged});

  final ValueChanged<String?> onRouteChanged;

  void _notify(Route<dynamic>? route) {
    onRouteChanged(route?.settings.name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify(previousRoute);
  }
}
