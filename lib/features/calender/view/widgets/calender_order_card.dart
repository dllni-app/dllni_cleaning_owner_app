import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/worker_booking_schedule_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/source/worker_session_remote_data_source.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/worker_app_colors.dart';

import '../../../../generated/assets.dart';
import '../helpers/calendar_schedule_request_guard.dart';
import '../helpers/calendar_session_selection.dart';
import '../../../orders/data/models/fetch_orders_usecase_model.dart';
import '../../../orders/view/screens/order_details_screen.dart';

class CalenderOrderCard extends StatefulWidget {
  const CalenderOrderCard({super.key, required this.date, required this.index});

  final FetchOrdersUsecaseModelDataItem date;
  final int index;

  @override
  State<CalenderOrderCard> createState() => _CalenderOrderCardState();
}

class _CalenderOrderCardState extends State<CalenderOrderCard> {
  WorkerBookingScheduleModel? _schedule;
  final CalendarScheduleRequestGuard _scheduleRequestGuard =
      CalendarScheduleRequestGuard();

  bool get _isEventAssistance =>
      widget.date.propertyType?.trim().toLowerCase() == 'event_assistance';

  @override
  void initState() {
    super.initState();
    if (_isEventAssistance && widget.date.id != null) {
      _fetchSchedule();
    }
  }

  @override
  void didUpdateWidget(covariant CalenderOrderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A refreshed booking DTO may keep the same ID while its assignment,
    // authorization or status has changed. Treat each new snapshot as a new
    // read boundary rather than reusing a previous session schedule.
    if (!identical(oldWidget.date, widget.date)) {
      _scheduleRequestGuard.invalidate();
      _schedule = null;
      if (_isEventAssistance && widget.date.id != null) {
        _fetchSchedule();
      }
    }
  }

  @override
  void dispose() {
    _scheduleRequestGuard.invalidate();
    super.dispose();
  }

  Future<void> _fetchSchedule() async {
    final bookingId = widget.date.id;
    if (bookingId == null) return;
    final requestGeneration = _scheduleRequestGuard.begin(bookingId);
    try {
      final result = await getIt<WorkerSessionRemoteDataSource>()
          .fetchBookingSchedule(bookingId);
      if (!mounted ||
          !_scheduleRequestGuard.acceptsResponse(
            generation: requestGeneration,
            bookingId: bookingId,
            responseBookingId: result.bookingId,
          )) {
        return;
      }
      setState(() => _schedule = result.schedule);
    } catch (_) {
      // Keep the legacy occurrence available if schedule loading fails.
    }
  }

  List<WorkerBookingSessionModel> _selectedSessions(BuildContext context) {
    final schedule = _schedule;
    if (schedule == null || !schedule.isMultiDay) {
      return const <WorkerBookingSessionModel>[];
    }

    final selectedDate = context
        .read<OrdersBloc>()
        .lastAppliedOrdersListFilter
        .scheduledDate;
    return selectCalendarSessionsForDate(
      schedule: schedule,
      selectedDate: selectedDate,
    );
  }

  String _sessionHours(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

  String _money(num value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final order = widget.date;
    final schedule = _schedule;
    final sessions = _selectedSessions(context);

    if (sessions.isEmpty) {
      return _buildOccurrence(
        context,
        order: order,
        session: null,
        schedule: schedule,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < sessions.length; index++) ...[
          if (index > 0) SizedBox(height: 12.h),
          _buildOccurrence(
            context,
            order: order,
            session: sessions[index],
            schedule: schedule,
          ),
        ],
      ],
    );
  }

  Widget _buildOccurrence(
    BuildContext context, {
    required FetchOrdersUsecaseModelDataItem order,
    required WorkerBookingSessionModel? session,
    required WorkerBookingScheduleModel? schedule,
  }) {
    final displayTime = session?.time ?? order.scheduledTime;
    final displayDate = session == null
        ? order.scheduledDate
        : calendarDateKey(session.date);
    final workerAmount =
        session?.workerAssignmentState?.workerAmount ??
        session?.workerAssignmentState?.netAmount;
    final displayedProfit = workerAmount ?? order.workerNetProfit;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52.w,
          child: AppText.labelMedium(
            CleaningArabicTimeFormatter.formatScheduledTime(
              displayTime,
              emptyValue: '',
            ),
            scrollText: true,
          ),
        ),
        SizedBox(width: 13.w),
        Expanded(
          child: InkWell(
            onTap: () {
              context.pushRoute(
                '/orderdetails',
                arguments: OrderDetailsScreenParams(
                  bloc: context.read<OrdersBloc>(),
                  index: widget.index,
                  order: order,
                  isNewOrder: false,
                  selectedSessionId: session?.id,
                ),
              );
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              decoration: BoxDecoration(
                color: WorkerAppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: WorkerAppColors.border),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 10.w,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText.labelLarge(
                              order.locationName ?? '',
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (schedule?.isMultiDay == true && session != null)
                            Container(
                              padding: EdgeInsetsDirectional.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: WorkerAppColors.brandPrimarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: AppText.labelSmall(
                                'الجلسة ${session.sequence}/${schedule!.daysCount}',
                                color: WorkerAppColors.brandPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Divider(height: 1, color: WorkerAppColors.border),
                    SizedBox(height: 12.h),
                    dataRow(
                      Assets.images.orderCardCalender.path,
                      'جدولة الحجز',
                      CleaningArabicTimeFormatter.toWesternDigits(
                        CleaningArabicTimeFormatter.formatCalendarIsoDate(
                          displayDate,
                          emptyValue: '',
                        ),
                      ),
                    ),
                    if (session != null) ...[
                      SizedBox(height: 12.h),
                      dataRow(
                        Assets.images.orderCardAlarm.path,
                        'مدة الجلسة',
                        '${CleaningArabicTimeFormatter.toWesternDigits(_sessionHours(session.hours))} ساعة',
                      ),
                    ],
                    SizedBox(height: 12.h),
                    dataRow(
                      Assets.images.orderCardBuilding.path,
                      'نوع العقار',
                      _propertyTypeInArabic(order.propertyType),
                    ),
                    if (session == null) ...[
                      SizedBox(height: 12.h),
                      dataRow(
                        Assets.images.orderCardAlarm.path,
                        'المساحة التقديرية',
                        order.estimatedSqm == null ||
                                order.estimatedSqm!.isEmpty
                            ? ''
                            : '${CleaningArabicTimeFormatter.toWesternDigits(order.estimatedSqm!)} متر مربع',
                      ),
                    ],
                    SizedBox(height: 12.h),
                    Divider(height: 1, color: WorkerAppColors.border),
                    SizedBox(height: 12.h),
                    Padding(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 10.w,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          order.customer?.phone == null
                              ? const SizedBox.shrink()
                              : InkWell(
                                  onTap: () async {
                                    callPhone(order.customer!.phone!);
                                  },
                                  child: CircleAvatar(
                                    radius: 15.r,
                                    backgroundColor:
                                        WorkerAppColors.brandPrimarySoft,
                                    child: Icon(
                                      Icons.phone_outlined,
                                      color: WorkerAppColors.brandPrimary,
                                      size: 15.sp,
                                    ),
                                  ),
                                ),
                          AppText.titleSmall(
                            '${CleaningArabicTimeFormatter.toWesternDigits(_money(displayedProfit))} ل.س',
                            color: WorkerAppColors.success,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _propertyTypeInArabic(String? propertyType) {
    switch (propertyType?.trim().toLowerCase()) {
      case 'apartment':
        return 'شقة';
      case 'villa':
        return 'فيلا';
      case 'house':
        return 'منزل';
      case 'office':
        return 'مكتب';
      case 'studio':
        return 'استوديو';
      case 'event_assistance':
        return 'مساعدة مناسبات';
      case null:
      case '':
        return '';
      default:
        return propertyType ?? '';
    }
  }

  Future<void> callPhone(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget dataRow(image, title, data) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w),
      child: Row(
        children: [
          AppImage.asset(image, size: 15),
          SizedBox(width: 8.w),
          AppText.labelMedium(title, fontWeight: FontWeight.w300),
          const Spacer(),
          Flexible(
            child: AppText.labelMedium(
              data,
              fontWeight: FontWeight.w300,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
