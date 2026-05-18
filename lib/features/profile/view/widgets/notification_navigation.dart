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

  if (routeKey.contains('dispute')) {
    final disputeId = _intFromData(data, const ['disputeId', 'dispute_id']);
    if (disputeId != null && context.mounted) {
      context.pushRoute(
        '/transactiondetails',
        arguments: TransactionDetailsScreenParam(id: disputeId, title: '#$disputeId', isOpen: true),
      );
    }
    return;
  }

  final m = (module ?? 'cleaning').toLowerCase();
  if (m != 'cleaning') return;

  final bookingId = _intFromData(data, const ['bookingId', 'booking_id', 'orderId', 'order_id']);
  if (bookingId == null) return;

  final response = await getIt<FetchOrderDetailsUsecaseUseCase>()(FetchOrderDetailsUsecaseParams(id: bookingId));
  if (!context.mounted) return;

  response.fold(
    (failure) => AppToast.showErrorGlobal(failure.message),
    (result) {
      final details = result.data;
      if (details == null || !context.mounted) return;

      final order = FetchOrdersUsecaseModelDataItem.fromJson(details.toJson());
      final isNewOrder = routeKey.contains('new_order') || legacyType == 'new_order';

      context.pushRoute(
        '/orderdetails',
        arguments: OrderDetailsScreenParams(
          order: order,
          isNewOrder: isNewOrder,
          bloc: getIt<OrdersBloc>(),
          index: 0,
        ),
      );
    },
  );
}

int? _intFromData(Map<String, dynamic> data, List<String> keys) {
  for (final k in keys) {
    final v = data[k];
    if (v == null) continue;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
  }
  return null;
}
