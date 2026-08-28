import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:flutter/material.dart';

import '../widgets/app_page_header.dart';
import '../widgets/app_state_view.dart';

class CleaningNotificationOrderLoaderScreen extends StatefulWidget {
  const CleaningNotificationOrderLoaderScreen({
    super.key,
    required this.bookingId,
  });

  final int bookingId;

  @override
  State<CleaningNotificationOrderLoaderScreen> createState() =>
      _CleaningNotificationOrderLoaderScreenState();
}

class _CleaningNotificationOrderLoaderScreenState
    extends State<CleaningNotificationOrderLoaderScreen> {
  FetchOrdersUsecaseModelDataItem? _order;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final response = await getIt<FetchOrderDetailsUsecaseUseCase>()(
      FetchOrderDetailsUsecaseParams(id: widget.bookingId),
    );

    if (!mounted) return;

    response.fold(
      (failure) {
        setState(() {
          _loading = false;
          _error = ErrorMessageFormatter.format(failure.message);
        });
      },
      (result) {
        final details = result.data;
        if (details == null) {
          setState(() {
            _loading = false;
            _error = 'تعذر تحميل تفاصيل الطلب';
          });
          return;
        }

        setState(() {
          _loading = false;
          _order = FetchOrdersUsecaseModelDataItem.fromJson(details.toJson());
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order != null) {
      return OrderDetailsScreen(
        params: OrderDetailsScreenParams(
          order: order,
          isNewOrder: false,
          bloc: getIt<OrdersBloc>(),
          index: 0,
        ),
      );
    }

    return Scaffold(
      appBar: const AppPageHeader(
        title: 'تفاصيل الطلب',
        subtitle: 'فتح الطلب من الإشعار',
      ),
      body: _loading
          ? const AppStateView.loading(message: 'جارٍ تحميل الطلب…')
          : AppStateView.error(
              message: _error ?? 'تعذر تحميل تفاصيل الطلب',
              onRetry: _load,
            ),
    );
  }
}
