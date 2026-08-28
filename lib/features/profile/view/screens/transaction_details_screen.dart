import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/theme/app_layout.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_bottom_action_bar.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_button.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_page_header.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_section_header.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_state_view.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_status_chip.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_surface_card.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_dispute_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/fetch_dispute_details_usecase_model.dart';
import '../manager/bloc/profile_bloc.dart';

@AutoRoutePage()
class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({super.key, required this.params});

  final TransactionDetailsScreenParam params;

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool _isReplying = false;
  final _responseController = TextEditingController();
  String? _selectedResolution;

  static const _resolutionOptions = <String, String>{
    'full_refund': 'استرداد كامل',
    'partial_refund': 'استرداد جزئي',
    'worker_penalty': 'جزاء على العامل',
    'dismissed': 'مرفوض',
  };

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _reload(BuildContext context) {
    context.read<ProfileBloc>().add(
      FetchDisputeDetailsUsecaseEvent(
        params: FetchDisputeDetailsUsecaseParams(id: widget.params.id),
      ),
    );
  }

  void _submit(BuildContext context, FetchDisputeDetailsUsecaseModelData data) {
    context.read<ProfileBloc>().add(
      UpdateDisputeEvent(
        params: UpdateDisputeParams(
          disputeId: data.id!,
          bookingId: data.bookingId!,
          bookingType: data.bookingType!,
          ticketNumber: data.ticketNumber!,
          category: data.category!,
          status: data.status!,
          resolution: _selectedResolution ?? data.resolution!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (_) => getIt<ProfileBloc>()
        ..add(
          FetchDisputeDetailsUsecaseEvent(
            params: FetchDisputeDetailsUsecaseParams(id: widget.params.id),
          ),
        ),
      child: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.updateDisputeStatus != current.updateDisputeStatus,
        listener: (context, state) {
          if (state.updateDisputeStatus == BlocStatus.success) {
            Loading.close();
            context.pop();
          } else if (state.updateDisputeStatus == BlocStatus.failed) {
            Loading.close();
            AppToast.showErrorGlobal(
              ErrorMessageFormatter.format(
                state.errorMessage,
                fallback: 'تعذر إرسال الرد',
              ),
            );
          } else if (state.updateDisputeStatus == BlocStatus.loading) {
            Loading.show(context);
          }
        },
        child: Scaffold(
          appBar: AppPageHeader(
            title: 'تفاصيل النزاع',
            subtitle: 'رقم التذكرة: ${widget.params.title}',
          ),
          body: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state.disputeDetailsUsecaseStatus == BlocStatus.loading ||
                  state.disputeDetailsUsecaseStatus == null) {
                return const AppStateView.loading(
                  message: 'جارٍ تحميل تفاصيل النزاع…',
                );
              }
              if (state.disputeDetailsUsecaseStatus == BlocStatus.failed) {
                return AppStateView.error(
                  message: ErrorMessageFormatter.format(
                    state.errorMessage,
                    fallback: 'تعذر تحميل تفاصيل النزاع',
                  ),
                  onRetry: () => _reload(context),
                );
              }
              final data = state.disputeDetailsUsecase?.data;
              if (data == null) {
                return AppStateView.empty(
                  message: 'لا توجد تفاصيل متاحة لهذا النزاع',
                  onRetry: () => _reload(context),
                );
              }
              return _DisputeContent(
                data: data,
                isReplying: _isReplying,
                selectedResolution: _selectedResolution,
                resolutionOptions: _resolutionOptions,
                responseController: _responseController,
                onResolutionChanged: (value) =>
                    setState(() => _selectedResolution = value),
              );
            },
          ),
          bottomNavigationBar: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final data = state.disputeDetailsUsecase?.data;
              if (state.disputeDetailsUsecaseStatus != BlocStatus.success ||
                  data == null ||
                  !widget.params.isOpen) {
                return const SizedBox.shrink();
              }
              return AppBottomActionBar(
                child: AppButton(
                  label: _isReplying ? 'إرسال الرد' : 'الرد على الشكوى',
                  icon: _isReplying ? Icons.send_rounded : Icons.reply_rounded,
                  isLoading: state.updateDisputeStatus == BlocStatus.loading,
                  onPressed: _isReplying
                      ? () => _submit(context, data)
                      : () => setState(() => _isReplying = true),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DisputeContent extends StatelessWidget {
  const _DisputeContent({
    required this.data,
    required this.isReplying,
    required this.selectedResolution,
    required this.resolutionOptions,
    required this.responseController,
    required this.onResolutionChanged,
  });

  final FetchDisputeDetailsUsecaseModelData data;
  final bool isReplying;
  final String? selectedResolution;
  final Map<String, String> resolutionOptions;
  final TextEditingController responseController;
  final ValueChanged<String?> onResolutionChanged;

  @override
  Widget build(BuildContext context) {
    final messages = data.messages ?? const <DisputeMessage>[];
    final closed = data.status?.toLowerCase() == 'closed';
    return ListView(
      padding: AppSpace.pagePadding(context).add(
        const EdgeInsetsDirectional.only(top: AppSpace.md, bottom: AppSpace.xl),
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: AppSectionHeader(
                title: 'ملخص النزاع',
                subtitle: data.category ?? 'شكوى خدمة',
              ),
            ),
            AppStatusChip(
              label: closed ? 'مغلق' : 'قيد المراجعة',
              tone: closed ? AppStatusTone.neutral : AppStatusTone.warning,
              icon: closed ? Icons.lock_outline : Icons.schedule_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        AppSurfaceCard(
          emphasized: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'محتوى الشكوى',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.md),
              if (messages.isEmpty)
                Text(
                  'لا توجد رسائل مضافة',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                for (var index = 0; index < messages.length; index++) ...[
                  _MessageItem(index: index + 1, body: messages[index].body),
                  if (index < messages.length - 1)
                    const Divider(height: AppSpace.lg),
                ],
            ],
          ),
        ),
        if (isReplying) ...[
          const SizedBox(height: AppSpace.lg),
          const AppSectionHeader(
            title: 'إضافة الرد',
            subtitle: 'اختر الحل وأضف ملاحظاتك بوضوح',
          ),
          const SizedBox(height: AppSpace.sm),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedResolution,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الحل المقترح',
                    prefixIcon: Icon(Icons.fact_check_outlined),
                  ),
                  items: resolutionOptions.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: onResolutionChanged,
                ),
                const SizedBox(height: AppSpace.md),
                TextFormField(
                  controller: responseController,
                  minLines: 4,
                  maxLines: 7,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات الرد',
                    hintText: 'اكتب توضيحك هنا',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({required this.index, required this.body});

  final int index;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text('$index'),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            body?.trim().isNotEmpty == true ? body!.trim() : 'رسالة بلا محتوى',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class TransactionDetailsScreenParam {
  final int id;
  final String title;
  final bool isOpen;

  TransactionDetailsScreenParam({
    required this.id,
    required this.title,
    required this.isOpen,
  });
}
