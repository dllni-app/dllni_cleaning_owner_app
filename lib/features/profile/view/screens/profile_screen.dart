import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/helpers/worker_profile_completeness_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/mission_start_location_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/update_profile_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/wallet_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/work_areas_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/working_time_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../manager/bloc/profile_bloc.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _openMissionStartLocationScreen(ProfileBloc profileBloc) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: const MissionStartLocationScreen(),
        ),
      ),
    );
    if (!mounted || saved != true) return;
  }

  Widget? _buildSectionTrailingForIndex(
    int sectionIndex,
    WorkerProfileCompletenessResult completeness,
  ) {
    final isIncomplete = isProfileSectionIncompleteByIndex(
      sectionIndex,
      completeness,
    );
    if (!isIncomplete) return null;
    return IncompleteSectionWarningIcon(size: 19.sp);
  }

  Future<void> _logout(BuildContext context) async {
    await getIt<CleaningBookingPusherService>().disposeAllForSession();
    await SharedPreferencesHelper.clearData();
    if (!context.mounted) return;
    context.pushRouteAndRemoveUntil('/login');
  }

  @override
  Widget build(BuildContext context) {
    const titles = <String>[
      'تعديل ملفي الشخصي',
      'مناطق عملي',
      'موقع بدء المهمة',
      'أوقات العمل',
      'سجل المعاملات',
      'الدعم والمساعدة',
    ];
    const subtitles = <String>[
      'لتعديل بيانات العرض',
      'يمكنك إدارة أماكن عملك',
      'للمساعدة على حساب تكلفة التنقل',
      'يمكنك تعديل أوقات عملك',
      'يمكنك تتبع أدائك',
      'التواصل مع الدعم الفني',
    ];
    const images = <IconData>[
      Icons.person,
      Icons.location_on_outlined,
      Icons.flag_outlined,
      Icons.alarm,
      Icons.signal_cellular_alt,
      Icons.headphones,
    ];

    const colors = <Color>[
      Color(0xff3B82F6),
      Color(0xffEAB308),
      Color(0xffF97316),
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
        ),
      child: SafeArea(
        child: Column(
          children: [
            const ProfileAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: 24.w,
                  vertical: 14.h,
                ),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final profileBloc = context.read<ProfileBloc>();
                        return SectionCard(
                          containerColor: const Color(0xff0EA5E9).withAlpha(27),
                          title: 'احصائاتي',
                          image: Icons.account_balance_wallet_outlined,
                          imageColor: const Color(0xff0EA5E9),
                          subtitle: 'مخططات الحجوزات والفواتير والملخص المالي',
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => BlocProvider.value(
                                  value: profileBloc,
                                  child: const WalletScreen(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
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
                        const SizedBox(width: 8),
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
                            final profileData =
                                state.workerProfileUsecase?.data;
                            final completeness =
                                evaluateWorkerProfileCompleteness(profileData);
                            final profileBloc = context.read<ProfileBloc>();
                            return SectionCard(
                              containerColor: colors[i].withAlpha(27),
                              title: titles[i],
                              image: images[i],
                              imageColor: colors[i],
                              subtitle: subtitles[i],
                              titleTrailing: _buildSectionTrailingForIndex(
                                i,
                                completeness,
                              ),
                              onTap: i == 0
                                  ? () {
                                      if (profileData == null) return;
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => BlocProvider.value(
                                            value: profileBloc,
                                            child: UpdateProfileScreen(
                                              params:
                                                  UpdateProfileScreenParams.fromWorkerProfile(
                                                    profileData,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  : i == 1
                                  ? () {
                                      context.pushRoute(
                                        '/workareas',
                                        arguments: WorkAreasScreenParams(
                                          zones:
                                              profileData?.zones ??
                                              const <Zone>[],
                                        ),
                                      );
                                    }
                                  : i == 2
                                  ? () async {
                                      await _openMissionStartLocationScreen(
                                        profileBloc,
                                      );
                                    }
                                  : i == 3
                                  ? () {
                                      final defaultHours =
                                          profileData?.defaultWorkingHours;
                                      if (defaultHours == null) return;
                                      context.pushRoute(
                                        '/workingtime',
                                        arguments: WorkingTimeScreenParams(
                                          defaultWorkingHours: defaultHours,
                                        ),
                                      );
                                    }
                                  : i == 4
                                  ? () {
                                      context.pushRoute('/transactionhistory');
                                    }
                                  : () async {
                                      await launchUrl(
                                        Uri.parse(
                                          'https://wa.me/message/XJOZBNT3VS5SJ1',
                                        ),
                                      );
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
                          color: const Color(0xff727791).withAlpha(6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xff727791).withAlpha(52),
                          ),
                        ),
                        padding: const EdgeInsetsDirectional.symmetric(
                          vertical: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: context.primaryContainer,
                            ),
                            const SizedBox(width: 12),
                            AppText.bodyMedium(
                              'تسجيل الخروج',
                              color: context.primaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
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
  const CustomMiniSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

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
