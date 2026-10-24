import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/transaction_details_screen.dart';
import 'package:flutter/material.dart';

Future<void> tryNavigateFromNotificationPayload(
  BuildContext context, {
  required String? module,
  required String? canonicalType,
  required String? type,
  required Map<String, dynamic>? data,
}) async {
  if (data == null || data.isEmpty) return;

  final canonical = (canonicalType ?? '').trim();
  final legacyType = (type ?? '').trim().toLowerCase();
  final routeKey = canonical.isNotEmpty ? canonical : legacyType;
  final isNewOrder =
      routeKey.contains('new_order') || legacyType == 'new_order';

  if (isNewOrder && _isUnavailable(data)) {
    AppToast.showErrorGlobal('لم يعد هذا الطلب متاحًا');
    return;
  }

  final m = (module ?? 'cleaning').trim().toLowerCase();
  if (m != 'cleaning') return;

  if (routeKey.contains('dispute')) {
    final disputeId = _positiveIdFromAliases(data, const [
      'disputeId',
      'dispute_id',
    ]);
    if (disputeId.value != null && context.mounted) {
      context.pushRoute(
        '/transactiondetails',
        arguments: TransactionDetailsScreenParam(
          id: disputeId.value!,
          title: '#${disputeId.value}',
          isOpen: true,
        ),
      );
    }
    return;
  }

  final bookingId = _positiveIdFromAliases(data, const [
    'bookingId',
    'booking_id',
    'orderId',
    'order_id',
  ]);
  if (bookingId.value == null) return;

  final sessionId = _positiveIdFromAliases(data, const [
    'sessionId',
    'session_id',
    'cleaningBookingSessionId',
    'cleaning_booking_session_id',
  ]);
  if (sessionId.isPresent && sessionId.value == null) return;

  final response = await getIt<FetchOrderDetailsUsecaseUseCase>()(
    FetchOrderDetailsUsecaseParams(id: bookingId.value!),
  );
  if (!context.mounted) return;

  response.fold(
    (failure) =>
        AppToast.showErrorGlobal(ErrorMessageFormatter.format(failure.message)),
    (result) {
      final details = result.data;
      if (details == null ||
          details.id != bookingId.value ||
          !context.mounted) {
        return;
      }

      final order = FetchOrdersUsecaseModelDataItem.fromJson(details.toJson());

      context.pushRoute(
        '/orderdetails',
        arguments: OrderDetailsScreenParams(
          order: order,
          isNewOrder: isNewOrder,
          bloc: getIt<OrdersBloc>(),
          index: 0,
          selectedSessionId: sessionId.value,
        ),
      );
    },
  );
}

bool _isUnavailable(Map<String, dynamic> data) {
  final state = (data['state'] ?? '').toString().trim().toLowerCase();
  if (state == 'unavailable') return true;

  final actionable = data['actionable'];
  if (actionable is bool) return !actionable;
  if (actionable is num) return actionable == 0;
  if (actionable is String) {
    final normalized = actionable.trim().toLowerCase();
    return normalized == 'false' || normalized == '0' || normalized == 'no';
  }

  return false;
}

_ExplicitId _positiveIdFromAliases(
  Map<String, dynamic> data,
  List<String> keys,
) {
  var isPresent = false;
  int? resolved;
  for (final k in keys) {
    if (!data.containsKey(k)) continue;
    isPresent = true;
    final candidate = _positiveInteger(data[k]);
    if (candidate == null || (resolved != null && resolved != candidate)) {
      return _ExplicitId(isPresent: true, value: null);
    }
    resolved = candidate;
  }

  return _ExplicitId(isPresent: isPresent, value: resolved);
}

int? _positiveInteger(dynamic value) {
  if (value is int) return value > 0 ? value : null;
  if (value is num) {
    if (!value.isFinite ||
        value <= 0 ||
        value >= 9223372036854775808.0 ||
        value != value.truncateToDouble()) {
      return null;
    }
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }
  return null;
}

class _ExplicitId {
  const _ExplicitId({required this.isPresent, required this.value});

  final bool isPresent;
  final int? value;
}
