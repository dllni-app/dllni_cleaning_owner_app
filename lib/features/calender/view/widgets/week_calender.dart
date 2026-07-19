import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/manager/calender_notifier.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:table_calendar/table_calendar.dart';

class WeekCalendar extends StatefulWidget {
  const WeekCalendar({super.key, required this.calenderNotifier});

  final CalenderNotifier calenderNotifier;

  @override
  State<WeekCalendar> createState() => _WeekCalendarState();
}

class _WeekCalendarState extends State<WeekCalendar> {
  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: 12.h),
        TableCalendar(
          locale: 'en',
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: focusedDay,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: CalendarFormat.week,
          headerVisible: false,
          daysOfWeekVisible: true,
          rowHeight: 44.h,
          daysOfWeekHeight: 22.h,
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDay = selected;
              focusedDay = focused;
            });
            widget.calenderNotifier.changeSelectedDate(selected);
            context.read<OrdersBloc>().add(
              FetchOrdersUsecaseEvent(
                params: FetchOrdersUsecaseParams(
                  page: 1,
                  scheduledDate: DateFormat('yyyy-MM-dd', 'en').format(selected),
                ),
                isReload: true,
              ),
            );
          },
          onPageChanged: (focused) {
            setState(() {
              focusedDay = focused;
            });
          },
          daysOfWeekStyle: DaysOfWeekStyle(
            dowTextFormatter: (date, _) =>
                CleaningArabicTimeFormatter.arabicWeekdayShortName(date),
            weekdayStyle: TextStyle(
              color: context.onPrimaryContainer,
              fontSize: 12.sp,
            ),
            weekendStyle: TextStyle(
              color: context.onPrimaryContainer,
              fontSize: 12.sp,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) =>
                _buildDayCell(context, day, selected: false),
            selectedBuilder: (context, day, focused) =>
                _buildDayCell(context, day, selected: true),
            todayBuilder: (context, day, focused) =>
                _buildDayCell(context, day, selected: isSameDay(day, selectedDay)),
            outsideBuilder: (context, day, focused) =>
                _buildDayCell(context, day, selected: false),
          ),
          calendarStyle: CalendarStyle(
            isTodayHighlighted: false,
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              border: Border.all(color: context.primaryContainer, width: 2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: context.primaryContainer,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: context.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: TextStyle(color: context.onPrimaryContainer),
            weekendTextStyle: TextStyle(color: context.onPrimaryContainer),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required bool selected,
  }) {
    return Center(
      child: Container(
        width: 36.r,
        height: 36.r,
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                color: context.primaryContainer,
                shape: BoxShape.circle,
              )
            : null,
        child: Text(
          CleaningArabicTimeFormatter.formatCalendarDayNumber(day),
          style: TextStyle(
            color: context.onPrimaryContainer,
            fontWeight: selected ? FontWeight.bold : FontWeight.w400,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final startOfWeek = focusedDay.subtract(
      Duration(days: focusedDay.weekday % DateTime.daysPerWeek),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final title = CleaningArabicTimeFormatter.formatCalendarWeekRange(
      focusedDay,
      startOfWeek: startOfWeek,
      endOfWeek: endOfWeek,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                focusedDay = focusedDay.subtract(const Duration(days: 7));
              });
            },
            icon: Icon(Icons.chevron_left, color: context.onPrimaryContainer),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.onPrimaryContainer,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                focusedDay = focusedDay.add(const Duration(days: 7));
              });
            },
            icon: Icon(Icons.chevron_right, color: context.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
