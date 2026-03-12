import 'dart:async';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../data/models/arrive_model.dart';
import '../../../data/models/fetch_orders_usecase_model.dart';

class OrderDetailsMissionBody extends StatefulWidget {
  const OrderDetailsMissionBody({super.key, required this.order, required this.bloc, required this.services, required this.addons});

  final FetchOrdersUsecaseModelDataItem order;
  final OrdersBloc bloc;

  final List<Service> services;
  final List<Addon> addons;

  @override
  State<OrderDetailsMissionBody> createState() => _OrderDetailsMissionBodyState();
}

class _OrderDetailsMissionBodyState extends State<OrderDetailsMissionBody> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemainingTime() {
    if (widget.order.arrivedAt == null) {
      setState(() {
        _remainingTime = Duration.zero;
      });
      return;
    }
    try {
      final arrivedAt = DateTime.tryParse(widget.order.arrivedAt!);
      if (arrivedAt == null) {
        setState(() {
          _remainingTime = Duration.zero;
        });
        return;
      }
      final estimatedHours = widget.order.estimatedHours ?? 0;
      final estimatedDuration = Duration(hours: estimatedHours.floor(), minutes: ((estimatedHours - estimatedHours.floor()) * 60).round());
      final endTime = arrivedAt.add(estimatedDuration);
      final now = DateTime.now();
      final remaining = endTime.difference(now);

      setState(() {
        _remainingTime = remaining.isNegative ? Duration.zero : remaining;
      });
    } catch (e) {
      setState(() {
        _remainingTime = Duration.zero;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemainingTime();
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  context.pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.black),
              ),
              12.horizontalSpace,
              Expanded(child: AppText.headlineMedium('تفاصيل الطلب ${widget.order.bookingNumber}', textAlign: TextAlign.start)),
            ],
          ),
          24.verticalSpace,
          _buildTimer(context),
          16.verticalSpace,
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: context.onPrimaryContainer,
              border: Border.all(color: Color(0xffF3F4F6), width: 1),
            ),
            padding: EdgeInsetsDirectional.all(25),
            child: Builder(
              builder: (context) {
                final taskStates = <bool>[false, false, false];
                return StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: context.primaryContainer,
                              child: Icon(Icons.checklist, color: context.onPrimaryContainer, size: 20),
                            ),
                            12.horizontalSpace,
                            Expanded(
                              child: AppText.titleSmall(
                                'قائمة المهام',
                                textAlign: TextAlign.start,
                                color: context.primaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        12.verticalSpace,
                        // Subtitle
                        AppText.bodyMedium('تحديد المهام التي قمت بتنفيذها', textAlign: TextAlign.start, color: Colors.grey[700]),
                        20.verticalSpace,
                        _buildTaskItem(
                          context: context,
                          title: 'تنظيف غرف النوم',
                          details: 'عدد 2',
                          isChecked: taskStates[0],
                          onChanged: (value) {
                            setState(() {
                              taskStates[0] = value ?? false;
                            });
                          },
                        ),
                        12.verticalSpace,
                        _buildTaskItem(
                          context: context,
                          title: 'تنظيف الحديقة',
                          details: 'قص العشب و سقي النباتات',
                          isChecked: taskStates[1],
                          onChanged: (value) {
                            setState(() {
                              taskStates[1] = value ?? false;
                            });
                          },
                        ),
                        12.verticalSpace,
                        _buildTaskItem(
                          context: context,
                          title: 'تنظيف المطبخ',
                          details: 'مع تنظيف البراد',
                          isChecked: taskStates[2],
                          onChanged: (value) {
                            setState(() {
                              taskStates[2] = value ?? false;
                            });
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          16.verticalSpace,
          BlocBuilder<OrdersBloc, OrdersState>(
            bloc: widget.bloc,
            builder: (context, state) {
              return InkWell(
                onTap: () {},
                child: Container(
                  width: context.width,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: context.primary),
                  padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 14),
                  child: state.startTravelUsecaseStatus == BlocStatus.loading
                      ? Center(
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: context.onPrimary)),
                        )
                      : AppText.labelLarge('إنهاء العمل', color: context.onPrimary, fontWeight: FontWeight.w500),
                ),
              );
            },
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: () {
              context.pushRoute('/emergencysos');
            },
            child: Container(
              width: context.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.error,
                border: Border.all(color: context.error),
              ),
              padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 14),
              child: AppText.labelLarge('SOS', color: context.onError, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(BuildContext context) {
    if (widget.order.arrivedAt == null) {
      return const SizedBox.shrink();
    }

    final timeString = _formatDuration(_remainingTime);
    return Center(
      child: AppText.bodyLarge(
        'متبقي $timeString لإنتهاء وقت الخدمة',
        textAlign: TextAlign.center,
        color: context.error,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTaskItem({
    required BuildContext context,
    required String title,
    required String details,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Color(0xffF3F4F6)),
      padding: EdgeInsetsDirectional.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(title, textAlign: TextAlign.start, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                4.verticalSpace,
                AppText.labelLarge(details, textAlign: TextAlign.start, color: Colors.grey[600]),
              ],
            ),
          ),
          12.horizontalSpace,
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            activeColor: context.primaryContainer,
            side: BorderSide(color: Color(0xffD1D5DB), width: 2),
          ),
        ],
      ),
    );
  }
}
