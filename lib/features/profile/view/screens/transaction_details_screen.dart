import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_dispute_details_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_dispute_use_case.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

import '../../../../generated/assets.dart';
import '../manager/bloc/profile_bloc.dart';

@AutoRoutePage()
class TransactionDetailsScreen extends StatefulWidget {
  const TransactionDetailsScreen({super.key, required this.params});

  final TransactionDetailsScreenParam params;

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  bool openMessageField = false;
  late TextEditingController responseController;

  String? _selectedResolution;

  final Map<String, String> _resolutionOptions = {
    'full_refund': 'استرداد كامل',
    'partial_refund': 'استرداد جزئي',
    'worker_penalty': 'جزاء على العامل',
    'dismissed': 'مرفوض',
  };

  @override
  void initState() {
    super.initState();
    responseController = TextEditingController();
  }

  @override
  void dispose() {
    responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (context) => getIt<ProfileBloc>()..add(FetchDisputeDetailsUsecaseEvent(params: FetchDisputeDetailsUsecaseParams(id: widget.params.id))),
      child: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) => previous.updateDisputeStatus != current.updateDisputeStatus,
        listener: (context, state) {
          if (state.updateDisputeStatus == BlocStatus.success) {
            Loading.close();
            context.pop();
          } else if (state.updateDisputeStatus == BlocStatus.failed) {
            Loading.close();
            AppToast.showToast(context: context, message: state.errorMessage ?? 'فشل في تحديث النزاع', type: ToastificationType.error);
          } else if (state.updateDisputeStatus == BlocStatus.loading) {
            Loading.show(context);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              context.pop();
                            },
                            child: Icon(Icons.arrow_back_ios_new, color: context.primary),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: AppText.bodyLarge(
                              'تفاصيل النزاع رقم #${widget.params.title}',
                              fontWeight: FontWeight.w700,
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 275,
                                child: Stack(
                                  alignment: AlignmentGeometry.center,
                                  children: [
                                    DottedBorder(
                                      options: RoundedRectDottedBorderOptions(
                                        radius: Radius.circular(24),
                                        color: context.primary,
                                        strokeWidth: 1,
                                        dashPattern: [8, 4],
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(color: context.primary.withAlpha(14), borderRadius: BorderRadius.circular(24)),
                                        width: context.width,
                                        height: 200,
                                        padding: EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 8),
                                        child: Column(
                                          children: [
                                            AppText.bodyLarge('محتوى الشكوى', color: context.primary),
                                            SizedBox(height: 20),
                                            Expanded(
                                              child: state.disputeDetailsUsecaseStatus == BlocStatus.success
                                                  ? SingleChildScrollView(
                                                      child: Column(
                                                        children: List.generate(
                                                          state.disputeDetailsUsecase!.data!.messages!.length,
                                                          (i) =>
                                                              AppText.labelLarge('${i + 1}-${state.disputeDetailsUsecase!.data!.messages![i].body!}'),
                                                        ),
                                                      ),
                                                    )
                                                  : Center(child: CircularProgressIndicator.adaptive()),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: context.width,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [AppImage.asset(Assets.images.disputeIcon.path)],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (openMessageField) ...[
                                _buildDropdownField(
                                  label: 'الحل',
                                  value: _selectedResolution,
                                  options: _resolutionOptions,
                                  onChanged: (val) => setState(() => _selectedResolution = val),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(color: context.primary.withAlpha(14), borderRadius: BorderRadius.circular(24)),
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 15, vertical: 12),
                                  child: TextFormField(
                                    controller: responseController,
                                    maxLines: null,
                                    minLines: 5,
                                    textDirection: TextDirection.rtl,
                                    decoration: InputDecoration(
                                      hintText: 'هنا نص الرد على الشكوى',
                                      hintTextDirection: TextDirection.rtl,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],
                              InkWell(
                                onTap: () {
                                  if (!openMessageField) {
                                    setState(() {
                                      openMessageField = true;
                                    });
                                  } else {
                                    if (state.disputeDetailsUsecaseStatus == BlocStatus.success) {
                                      final data = state.disputeDetailsUsecase!.data!;
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
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                                  width: context.width,
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 12),
                                  child: AppText.labelLarge(
                                    openMessageField ? 'إرسال الرد' : 'الرد على الشكوى',
                                    color: context.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required Map<String, String> options,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(label, fontWeight: FontWeight.w600),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.primary.withAlpha(14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          items: options.entries.map((e) {
            return DropdownMenuItem<String>(value: e.key, child: AppText.labelMedium(e.value));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class TransactionDetailsScreenParam {
  final int id;
  final String title;
  final bool isOpen;

  TransactionDetailsScreenParam({required this.id, required this.title, required this.isOpen});
}
