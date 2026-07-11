import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_order_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'تعذر تحميل تفاصيل الطلب',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
