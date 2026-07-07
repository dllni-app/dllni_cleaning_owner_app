import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_working_hours_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/widgets/working_time_app_bar.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/widgets/working_time_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

@AutoRoutePage()
class WorkingTimeScreen extends StatefulWidget {
  final WorkingTimeScreenParams params;

  const WorkingTimeScreen({super.key, required this.params});

  @override
  State<WorkingTimeScreen> createState() => _WorkingTimeScreenState();
}

class WorkingTimeScreenParams {
  final FetchWorkerProfileUsecaseModelDataDefaultWorkingHours
      defaultWorkingHours;

  WorkingTimeScreenParams({required this.defaultWorkingHours});
}

class _WorkingTimeScreenState extends State<WorkingTimeScreen> {
  static const List<String> _arabicDayNames = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];

  static const List<String> _englishDayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<GlobalKey<WorkingTimeCardState>> _cardKeys =
      List<GlobalKey<WorkingTimeCardState>>.generate(
    7,
    (_) => GlobalKey<WorkingTimeCardState>(),
  );

  FetchWorkerProfileUsecaseModelDataDefaultWorkingHours? _workingHours;

  void _resetCardKeys() {
    for (var i = 0; i < _cardKeys.length; i++) {
      _cardKeys[i] = GlobalKey<WorkingTimeCardState>();
    }
  }

  @override
  void initState() {
    super.initState();
    _workingHours = widget.params.defaultWorkingHours;
  }

  WorkingDay? _dayForIndex(
    FetchWorkerProfileUsecaseModelDataDefaultWorkingHours data,
    int index,
  ) {
    switch (index) {
      case 0:
        return data.sunday;
      case 1:
        return data.monday;
      case 2:
        return data.tuesday;
      case 3:
        return data.wednesday;
      case 4:
        return data.thursday;
      case 5:
        return data.friday;
      case 6:
        return data.saturday;
      default:
        return null;
    }
  }

  WorkingDay _collectDay(int index) {
    final fromCard = _cardKeys[index].currentState?.toWorkingDay();
    if (fromCard != null) return fromCard;

    final source = _workingHours ?? widget.params.defaultWorkingHours;
    return _dayForIndex(source, index) ?? WorkingDay.offline();
  }

  FetchWorkerProfileUsecaseModelDataDefaultWorkingHours _collectWorkingHours() {
    return FetchWorkerProfileUsecaseModelDataDefaultWorkingHours(
      sunday: _collectDay(0),
      monday: _collectDay(1),
      tuesday: _collectDay(2),
      wednesday: _collectDay(3),
      thursday: _collectDay(4),
      friday: _collectDay(5),
      saturday: _collectDay(6),
    );
  }

  bool _validateWorkingHours(
    FetchWorkerProfileUsecaseModelDataDefaultWorkingHours hours,
  ) {
    final days = [
      hours.sunday,
      hours.monday,
      hours.tuesday,
      hours.wednesday,
      hours.thursday,
      hours.friday,
      hours.saturday,
    ];

    for (final day in days) {
      if (day?.isWorking == true && (day?.hours.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  void _onSave(BuildContext context) {
    final payload = _collectWorkingHours();
    if (!_validateWorkingHours(payload)) {
      AppToast.showErrorGlobal(
        'يرجى تحديد فترة عمل كاملة لكل يوم مفعّل',
      );
      return;
    }

    context.read<ProfileBloc>().add(
          UpdateWorkerWorkingHoursEvent(
            params: UpdateWorkerWorkingHoursParams(
              defaultWorkingHours: payload,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayWeekday = today.weekday == 7 ? 0 : today.weekday;
    final workingHours = _workingHours ?? widget.params.defaultWorkingHours;

    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (_) {
        final bloc = getIt<ProfileBloc>();
        bloc.add(FetchWorkerWorkingHoursEvent());
        return bloc;
      },
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.fetchWorkingHoursStatus != current.fetchWorkingHoursStatus ||
            previous.updateWorkingHoursStatus != current.updateWorkingHoursStatus,
        listener: (context, state) {
          if (state.fetchWorkingHoursStatus == BlocStatus.success &&
              state.workingHours != null) {
            setState(() {
              _resetCardKeys();
              _workingHours = state.workingHours!.defaultWorkingHours;
            });
          }

          if (state.updateWorkingHoursStatus == BlocStatus.success) {
            if (state.workingHours != null) {
              setState(() {
                _workingHours = state.workingHours!.defaultWorkingHours;
              });
            }
            if (context.mounted) {
              context.pop();
            }
          }
        },
        builder: (context, state) {
          final isLoadingFetch =
              state.fetchWorkingHoursStatus == BlocStatus.loading &&
              _workingHours == null;
          final isSaving =
              state.updateWorkingHoursStatus == BlocStatus.loading;

          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  const WorkingTimeAppBar(),
                  16.verticalSpace,
                  if (isLoadingFetch)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: List.generate(7, (index) {
                            final isToday = index == todayWeekday;
                            final workingDay = _dayForIndex(workingHours, index);

                            return Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: WorkingTimeCard(
                                key: _cardKeys[index],
                                dayName: _arabicDayNames[index],
                                dayNameEn: _englishDayNames[index],
                                workingDay: workingDay,
                                isToday: isToday,
                                dayIndex: index,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  10.verticalSpace,
                  GestureDetector(
                    onTap: isSaving ? null : () => _onSave(context),
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 24.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.r),
                        color: isSaving
                            ? context.primary.withAlpha(127)
                            : context.primary,
                      ),
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: 12.w,
                        vertical: 16.h,
                      ),
                      child: isSaving
                          ? Center(
                              child: SizedBox(
                                width: 22.w,
                                height: 22.w,
                                child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : AppText.labelLarge(
                              'حفظ التغييرات',
                              color: context.onPrimary,
                              fontWeight: FontWeight.w500,
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                  10.verticalSpace,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
