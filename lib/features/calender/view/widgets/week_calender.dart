import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/manager/calender_notifier.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/worker_app_colors.dart';

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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            WorkerAppColors.brandPrimary,
            WorkerAppColors.brandPrimaryStrong,
          ],
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 14),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
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
            rowHeight: 52,
            daysOfWeekHeight: 22,
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
                    assignedToCurrentWorker: true,
                    acceptedByCurrentWorkerOnly: true,
                    scheduledDate: DateFormat(
                      'yyyy-MM-dd',
                      'en',
                    ).format(selected),
                  ),
                  isReload: true,
                ),
              );
            },
            onPageChanged: (focused) => setState(() => focusedDay = focused),
            daysOfWeekStyle: DaysOfWeekStyle(
              dowTextFormatter: (date, _) =>
                  CleaningArabicTimeFormatter.arabicWeekdayShortName(date),
              weekdayStyle: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 10,
              ),
              weekendStyle: const TextStyle(
                color: Color(0xCCFFFFFF),
                fontSize: 10,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focused) =>
                  _buildDayCell(day, selected: false),
              selectedBuilder: (context, day, focused) =>
                  _buildDayCell(day, selected: true),
              todayBuilder: (context, day, focused) =>
                  _buildDayCell(day, selected: isSameDay(day, selectedDay)),
              outsideBuilder: (context, day, focused) =>
                  _buildDayCell(day, selected: false),
            ),
            calendarStyle: const CalendarStyle(
              isTodayHighlighted: false,
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, {required bool selected}) {
    return Center(
      child: AnimatedContainer(
        duration: WorkerAppDurations.stateChange,
        width: 42,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          CleaningArabicTimeFormatter.toWesternDigits(
            CleaningArabicTimeFormatter.formatCalendarDayNumber(day),
          ),
          style: TextStyle(
            color: selected ? WorkerAppColors.brandPrimary : Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final start = focusedDay.subtract(
      Duration(days: focusedDay.weekday % DateTime.daysPerWeek),
    );
    final end = start.add(const Duration(days: 6));
    final title = CleaningArabicTimeFormatter.toWesternDigits(
      CleaningArabicTimeFormatter.formatCalendarWeekRange(
        focusedDay,
        startOfWeek: start,
        endOfWeek: end,
      ),
    );
    return Row(
      children: [
        IconButton(
          onPressed: () => setState(
            () => focusedDay = focusedDay.subtract(const Duration(days: 7)),
          ),
          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(
            () => focusedDay = focusedDay.add(const Duration(days: 7)),
          ),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
