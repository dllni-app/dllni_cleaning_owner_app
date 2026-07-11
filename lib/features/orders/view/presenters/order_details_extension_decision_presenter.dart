import 'dart:async';

import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/features/main/navigation/main_tab_navigation.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/screens/main_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:flutter/material.dart';

class OrderDetailsExtensionDecisionPresenter {
  final Set<String> _handledExtensionDecisionKeys = <String>{};
  bool _extensionRejectedDialogOpen = false;

  void maybeShowExtensionRejectedDialog({
    required BuildContext context,
    required FetchOrdersUsecaseModelDataItem order,
    required Map<String, dynamic> payload,
  }) {
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    final decision = CleaningRealtimeContract.extractDecision(unwrapped);
    if (decision != 'extension_rejected') return;

    final currentStatus = (order.status ?? '').trim().toLowerCase();
    if (currentStatus != CleaningBookingStatus.timeExtensionRequested) return;

    final warningId = CleaningRealtimeContract.extractWarningId(unwrapped);
    final decisionKey = _extensionDecisionKey(
      payload: unwrapped,
      warningId: warningId,
      decision: decision ?? 'extension_rejected',
    );
    if (decisionKey != null &&
        _handledExtensionDecisionKeys.contains(decisionKey)) {
      return;
    }
    if (decisionKey != null) _handledExtensionDecisionKeys.add(decisionKey);

    unawaited(
      _showExtensionRejectedDialog(
        context: context,
        message: CleaningRealtimeContract.extractDecisionMessage(unwrapped),
      ),
    );
  }

  String? _extensionDecisionKey({
    required Map<String, dynamic> payload,
    required int? warningId,
    required String decision,
  }) {
    if (warningId != null) return 'warning_$warningId';
    final unwrapped = CleaningRealtimeContract.unwrapPayload(payload);
    final bookingId = CleaningRealtimeContract.extractBookingId(unwrapped);
    final decidedAt = (unwrapped['decidedAt'] ?? unwrapped['decided_at'])
        ?.toString();
    if (bookingId == null) return null;
    return '${bookingId}_${decision}_$decidedAt';
  }

  Future<void> _showExtensionRejectedDialog({
    required BuildContext context,
    required String? message,
  }) async {
    if (!context.mounted || _extensionRejectedDialogOpen) return;
    _extensionRejectedDialogOpen = true;
    try {
      final body = message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'تم رفض طلب تمديد الوقت وتم إنهاء الطلب.';
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text(
              'تم إنهاء طلب التمديد',
              textAlign: TextAlign.center,
            ),
            content: Text(body, textAlign: TextAlign.center),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final navigator = Navigator.of(ctx, rootNavigator: true);
                    navigator.pop();
                    final opened = MainTabNavigation.instance.jumpToTab(0);
                    if (!opened) {
                      navigator.pushNamedAndRemoveUntil(
                        '/main',
                        (route) => false,
                        arguments: MainScreenParam(returnedPageIndex: 0),
                      );
                    }
                  },
                  child: const Text('حسناً'),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      _extensionRejectedDialogOpen = false;
    }
  }
}
