import 'package:common_package/annotations/auto_route_page.dart';
import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';

import '../../data/models/fetch_worker_profile_usecase_model.dart';
import '../widgets/working_time_app_bar.dart';
import '../widgets/working_time_card.dart';

@AutoRoutePage()
class WorkingTimeScreen extends StatefulWidget {
  const WorkingTimeScreen({super.key, required this.data});

  final FetchWorkerProfileUsecaseModelDataDefaultWorkingHours data;

  @override
  State<WorkingTimeScreen> createState() => _WorkingTimeScreenState();
}

class _WorkingTimeScreenState extends State<WorkingTimeScreen> {
  static const List<String> arabicDayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

  static const List<String> englishDayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const WorkingTimeAppBar(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final isToday = index == todayWeekday;
                  WorkingDay? workingDay;
                  switch (index) {
                    case 0:
                      workingDay = widget.data.sunday;
                      break;
                    case 1:
                      workingDay = widget.data.monday;
                      break;
                    case 2:
                      workingDay = widget.data.tuesday;
                      break;
                    case 3:
                      workingDay = widget.data.wednesday;
                      break;
                    case 4:
                      workingDay = widget.data.thursday;
                      break;
                    case 5:
                      workingDay = widget.data.friday;
                      break;
                    case 6:
                      workingDay = widget.data.saturday;
                      break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: WorkingTimeCard(
                      dayName: arabicDayNames[index],
                      dayNameEn: englishDayNames[index],
                      workingDay: workingDay,
                      isToday: isToday,
                      dayIndex: index,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.primary,
                      ),
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 16),
                      child: AppText.labelLarge('حفظ التغييرات', color: context.onPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.error.withAlpha(50),
                        border: Border.all(color: context.error),
                      ),
                      padding: EdgeInsetsDirectional.symmetric(horizontal: 6, vertical: 16),
                      child: AppText.labelLarge('إلغاء', color: context.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
}
