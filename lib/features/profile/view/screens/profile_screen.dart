import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_statistics_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/update_profile_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/work_areas_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/working_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../manager/bloc/profile_bloc.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/section_card.dart';
import '../widgets/statistics_line_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _resolveWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  Future<void> _logout(BuildContext context) async {
    final workerId = _resolveWorkerId();
    if (workerId != null) {
      final pusher = getIt<CleaningBookingPusherService>();
      pusher.setWorkerHandler(workerId, null);
      await pusher.unsubscribeWorkerChannel(workerId);
    }
    await SharedPreferencesHelper.clearData();
    if (!context.mounted) return;
    context.pushRouteAndRemoveUntil('/login');
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'تعديل ملفي الشخصي',
      'مناطق عملي',
      'أوقات العمل',
      'سجل المعاملات',
      'الدعم والمساعدة',
    ];
    final List<String> subtitles = [
      'لتعديل بيانات العرض',
      'يمكنك إدارة أماكن عملك ',
      'يمكنك تعديل أوقات عملك',
      'يمكنك تتبع أداءك',
      'التواصل مع الدعم الفني',
    ];
    final List<IconData> images = [
      Icons.person,
      Icons.location_on_outlined,
      Icons.alarm,
      Icons.signal_cellular_alt,
      Icons.headphones,
    ];

    final List<Color> colors = [
      Color(0xff3B82F6),
      Color(0xffEAB308),
      Color(0xffA855F7),
      Color(0xff22C55E),
      Color(0xff6366F1),
    ];

    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (context) => getIt<ProfileBloc>()
        ..add(
          FetchWorkerProfileUsecaseEvent(
            params: FetchWorkerProfileUsecaseParams(),
          ),
        )
        ..add(
          FetchWorkerStatisticsEvent(params: FetchWorkerStatisticsParams()),
        ),
      child: SafeArea(
        child: Column(
          children: [
            ProfileAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                child: Column(
                  children: [
                    StatisticsLineChart(),
                    24.verticalSpace,
                    Row(
                      children: [
                        SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: Colors.black,
                            thickness: 4,
                            radius: BorderRadius.circular(9999),
                          ),
                        ),
                        SizedBox(width: 8),
                        AppText.titleMedium(
                          'إدارة الحساب',
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    Column(
                      spacing: 15.h,
                      children: List.generate(
                        titles.length,
                        (i) => BlocBuilder<ProfileBloc, ProfileState>(
                          builder: (context, state) {
                            return SectionCard(
                              containerColor: colors[i].withAlpha(27),
                              title: titles[i],
                              image: images[i],
                              imageColor: colors[i],
                              subtitle: subtitles[i],
                              onTap: i == 0
                                  ? () {
                                      context.pushRoute(
                                        '/updateprofile',
                                        arguments: UpdateProfileScreenParams(
                                          name: state
                                              .workerProfileUsecase!
                                              .data!
                                              .user!
                                              .name!,
                                          email: state
                                              .workerProfileUsecase
                                              ?.data
                                              ?.user
                                              ?.email,
                                          phone: state
                                              .workerProfileUsecase
                                              ?.data
                                              ?.user
                                              ?.phone,
                                          bio: state
                                              .workerProfileUsecase
                                              ?.data
                                              ?.bio,
                                          city: state
                                              .workerProfileUsecase
                                              ?.data
                                              ?.homeAddress,
                                        ),
                                      );
                                    }
                                  : i == 1
                                  ? () {
                                      context.pushRoute(
                                        '/workareas',
                                        arguments: WorkAreasScreenParams(
                                          zones: state
                                              .workerProfileUsecase!
                                              .data!
                                              .zones!,
                                        ),
                                      );
                                    }
                                  : i == 2
                                  ? () {
                                      context.pushRoute(
                                        '/workingtime',
                                        arguments: WorkingTimeScreenParams(
                                          defaultWorkingHours: state
                                              .workerProfileUsecase!
                                              .data!
                                              .defaultWorkingHours!,
                                        ),
                                      );
                                    }
                                  : i == 3
                                  ? () {
                                      context.pushRoute('/transactionhistory');
                                    }
                                  : () async {
                                      await _logout(context);
                                    },
                            );
                          },
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    InkWell(
                      onTap: () async {
                        await _logout(context);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xff727791).withAlpha(6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Color(0xff727791).withAlpha(52),
                          ),
                        ),
                        padding: EdgeInsetsDirectional.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: context.primaryContainer,
                            ),
                            SizedBox(width: 12),
                            AppText.bodyMedium(
                              'تسجيل الخروج',
                              color: context.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    /*24.verticalSpace,
                    Row(
                      children: [
                        AppText.labelLarge('حالة الحساب', color: context.primary, fontWeight: FontWeight.w500),
                        16.horizontalSpace,
                        BlocBuilder<ProfileBloc, ProfileState>(
                          builder: (context, state) {
                            return CustomMiniSwitch(
                              value: state.workerProfileUsecase?.data?.isActive ?? false,
                              onChanged: (val) {
                                setState(() {
                                  state.workerProfileUsecase?.data?.isActive = val;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),*/
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomMiniSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomMiniSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomMiniSwitch> createState() => _CustomMiniSwitchState();
}

class _CustomMiniSwitchState extends State<CustomMiniSwitch> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46.w,
        height: 22.h,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: BoxDecoration(
          color: widget.value
              ? Colors.green.withAlpha(63)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: widget.value
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 16.w,
            height: 16.h,
            decoration: BoxDecoration(
              color: widget.value ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
