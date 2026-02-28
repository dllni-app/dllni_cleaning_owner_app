import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/manager/calender_notifier.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        SizedBox(height: 12),
        TableCalendar(
          locale: 'ar',
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: CalendarFormat.week,
          headerVisible: false,
          daysOfWeekVisible: true,
          onDaySelected: (selected, focused) {
            setState(() {
              selectedDay = selected;
            });
            widget.calenderNotifier.changeSelectedDate(selected);
            context.read<OrdersBloc>().add(
              FetchOrdersUsecaseEvent(
                params: FetchOrdersUsecaseParams(page: 1, scheduledDate: DateFormat('yyyy-MM-dd').format(selected)),
                isReload: true,
              ),
            );
          },
          calendarStyle: CalendarStyle(
            isTodayHighlighted: false,
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              border: Border.all(color: context.primaryContainer, width: 2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(color: context.primaryContainer, shape: BoxShape.circle),
            selectedTextStyle: TextStyle(color: context.onPrimaryContainer, fontWeight: FontWeight.bold),
            defaultTextStyle: TextStyle(color: context.onPrimaryContainer),
            weekendTextStyle: TextStyle(color: context.onPrimaryContainer),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: context.onPrimaryContainer),
            weekendStyle: TextStyle(color: context.onPrimaryContainer),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final startOfWeek = focusedDay.subtract(Duration(days: focusedDay.weekday));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    final monthName = DateFormat.MMMM('ar').format(focusedDay);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                focusedDay = focusedDay.subtract(Duration(days: 7));
              });
            },
            icon: Icon(Icons.chevron_left, color: context.onPrimaryContainer),
          ),
          Text(
            "$monthName ${startOfWeek.day}_${endOfWeek.day}",
            style: TextStyle(color: context.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                focusedDay = focusedDay.add(Duration(days: 7));
              });
            },
            icon: Icon(Icons.chevron_right, color: context.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}
