import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/accept_order_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AcceptOrderBottomSheet extends StatelessWidget {
  const AcceptOrderBottomSheet({
    super.key,
    required this.order,
    required this.bloc,
    required this.index,
  });

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;
  final int index;

  static Future<void> show(
    BuildContext context, {
    required FetchOrdersUsecaseModelDataItem order,
    required OrdersBloc bloc,
    required int index,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AcceptOrderBottomSheet(
        order: order,
        bloc: bloc,
        index: index,
      ),
    );
  }

  String _serviceName() {
    final type = (order.propertyType ?? '').toLowerCase();
    switch (type) {
      case 'apartment':
        return 'تنظيف شقة';
      case 'house':
        return 'تنظيف منزل';
      case 'villa':
        return 'تنظيف فيلا';
      case 'studio':
        return 'تنظيف ستوديو';
      default:
        return 'تنظيف منزل';
    }
  }

  String _formatDate() {
    final raw = order.scheduledDate;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _formatTime() {
    final raw = order.scheduledTime;
    if (raw == null || raw.isEmpty) return '-';
    final parsed = DateTime.tryParse('2000-01-01T$raw');
    if (parsed == null) return raw;
    return DateFormat('hh:mm a').format(parsed);
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.primaryContainer),
        const SizedBox(width: 8),
        AppText.bodyLarge(title, fontWeight: FontWeight.bold),
      ],
    );
  }

  Widget _detailCard(BuildContext context, List<Widget> children) {
    return Container(
      width: context.width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height * .88,
      decoration: BoxDecoration(
        color: context.onPrimary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleMedium(
                        'قبول الطلب #${order.bookingNumber ?? order.id ?? '-'}',
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.start,
                      ),
                      AppText.bodySmall(
                        'يرجى تأكيد تفاصيل الطلب قبل القبول',
                        color: const Color(0xff6B7280),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => context.pop(),
                  child: const Icon(Icons.close, color: Color(0xff6B7280)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(context, Icons.cleaning_services_outlined, 'نوع الخدمة'),
                  const SizedBox(height: 10),
                  _detailCard(context, [
                    AppText.bodyMedium(
                      _serviceName(),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff111827),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionTitle(context, Icons.schedule, 'موعد ووقت الخدمة'),
                  const SizedBox(height: 10),
                  _detailCard(context, [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodySmall('التاريخ', color: const Color(0xff6B7280)),
                              const SizedBox(height: 4),
                              AppText.bodyMedium(_formatDate(), fontWeight: FontWeight.w700),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.bodySmall('الوقت', color: const Color(0xff6B7280)),
                              const SizedBox(height: 4),
                              AppText.bodyMedium(_formatTime(), fontWeight: FontWeight.w700),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _sectionTitle(context, Icons.checklist_rounded, 'الخدمات المطلوبة'),
                  const SizedBox(height: 10),
                  _detailCard(
                    context,
                    [
                      if ((order.services ?? []).isEmpty && (order.addons ?? []).isEmpty)
                        AppText.bodySmall('لا توجد بنود خدمة مفصلة', color: const Color(0xff6B7280)),
                      ...?order.services?.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppText.bodyMedium(
                                  s.name ?? 'خدمة',
                                  fontWeight: FontWeight.w700,
                                  textAlign: TextAlign.start,
                                ),
                              ),
                              AppText.bodySmall('x${s.quantity ?? 1}', color: const Color(0xff6B7280)),
                            ],
                          ),
                        ),
                      ),
                      ...?order.addons?.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppText.bodyMedium(
                                  a.name ?? 'إضافة',
                                  textAlign: TextAlign.start,
                                  color: const Color(0xff374151),
                                ),
                              ),
                              AppText.bodySmall('x${a.quantity ?? 1}', color: const Color(0xff6B7280)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle(context, Icons.location_on_outlined, 'عنوان العقار'),
                  const SizedBox(height: 10),
                  _detailCard(context, [
                    AppText.bodyMedium(
                      order.propertyDetails?.address ?? order.locationName ?? '-',
                      textAlign: TextAlign.start,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _detailCard(context, [
                    Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: context.primaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppText.bodySmall(
                            'سيتم إشعار العميل مباشرة بعد قبول الطلب',
                            color: context.primaryContainer,
                            fontWeight: FontWeight.w700,
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ],
                    ),
                  ]),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xffE5E7EB))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.error),
                        color: context.error.withAlpha(20),
                      ),
                      child: Center(
                        child: AppText.labelLarge(
                          'إلغاء',
                          color: context.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: BlocConsumer<OrdersBloc, OrdersState>(
                    bloc: bloc,
                    listener: (context, state) {
                      if (state.acceptOrderUsecaseStatus == BlocStatus.success) {
                        context.pop();
                      }
                    },
                    builder: (context, state) {
                      final loading = state.acceptOrderUsecaseStatus == BlocStatus.loading;
                      return InkWell(
                        onTap: loading
                            ? null
                            : () {
                                if (order.id == null) return;
                                bloc.add(
                                  AcceptOrderUsecaseEvent(
                                    params: AcceptOrderUsecaseParams(id: order.id!),
                                    index: index,
                                  ),
                                );
                              },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: context.primary,
                          ),
                          child: Center(
                            child: loading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.onPrimary,
                                    ),
                                  )
                                : AppText.labelLarge(
                                    'تأكيد القبول',
                                    color: context.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
