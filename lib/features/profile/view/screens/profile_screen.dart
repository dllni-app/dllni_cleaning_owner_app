import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/worker_technical_support_call_button.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/location/worker_location_tracker.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_booking_pusher_service.dart';
import 'package:dllni_cleaninig_owner_app/core/theme/app_semantic_colors.dart';
import 'package:dllni_cleaninig_owner_app/core/theme/app_layout.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_button.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/app_section_header.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/update_worker_profile_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/helpers/worker_profile_completeness_helper.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/mission_start_location_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/update_profile_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/wallet_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/work_areas_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/working_time_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/worker_reviews_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../manager/bloc/profile_bloc.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/section_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<bool> _openMissionStartLocationScreen(ProfileBloc profileBloc) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: profileBloc,
          child: const MissionStartLocationScreen(),
        ),
      ),
    );
    return mounted && saved == true;
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
    await WorkerLocationTracker.instance.stop();
    await getIt<CleaningBookingPusherService>().disposeAllForSession();
    await SharedPreferencesHelper.clearData();
    if (!context.mounted) return;
    context.pushRouteAndRemoveUntil('/login');
  }

  Future<bool> _confirmDeactivateAccount() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعطيل الحساب'),
        content: const Text(
          'في حال تعطيل حسابك لن تستقبل الطلبات حتى تعيد تفعيل الحساب',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تعطيل'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmSetMissionStartLocationForActivation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تحديد موقع بدء المهمة'),
        content: const Text(
          'لتفعيل الحساب واستقبال الطلبات يجب تحديد موقع بدء المهمة أولاً. هل تريد تحديد الموقع الآن؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تحديد الموقع'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onAccountActiveChanged(BuildContext context, bool value) async {
    final profileBloc = context.read<ProfileBloc>();

    if (value) {
      final completeness = evaluateWorkerProfileCompleteness(
        profileBloc.state.workerProfileUsecase?.data,
      );

      if (!completeness.hasMissionStartLocation) {
        final shouldSetLocation =
            await _confirmSetMissionStartLocationForActivation();
        if (!shouldSetLocation || !context.mounted) return;

        final saved = await _openMissionStartLocationScreen(profileBloc);
        if (!saved || !context.mounted) return;
      }

      profileBloc.add(
        UpdateWorkerProfileEvent(
          params: UpdateWorkerProfileParams(isActive: 1),
          showFeedback: true,
        ),
      );
      return;
    }

    final confirmed = await _confirmDeactivateAccount();
    if (!confirmed || !context.mounted) return;

    profileBloc.add(
      UpdateWorkerProfileEvent(
        params: UpdateWorkerProfileParams(isActive: 0),
        showFeedback: true,
      ),
    );
  }

  Widget _buildAccountActiveToggle(BuildContext context, ProfileState state) {
    final isActive = state.workerProfileUsecase?.data?.isActive ?? false;
    final isUpdating = state.updateWorkerProfileStatus == BlocStatus.loading;

    final toneColor = isActive
        ? context.semanticColors.success
        : context.semanticColors.warning;
    final toneContainer = isActive
        ? context.semanticColors.successContainer
        : context.semanticColors.warningContainer;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: toneContainer,
        border: Border.all(color: toneColor.withValues(alpha: 0.35)),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 12.w,
        vertical: 12.h,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
            ),
            padding: EdgeInsetsDirectional.all(8),
            child: Icon(
              Icons.power_settings_new,
              size: 25.sp,
              color: toneColor,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(
                  'تفعيل الحساب',
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.start,
                ),
                SizedBox(height: 4.h),
                AppText.labelLarge(
                  isActive
                      ? 'حسابك مفعل ويمكنك استقبال الطلبات'
                      : 'حسابك معطل ولن تستقبل طلبات',
                  fontWeight: FontWeight.w400,
                  color: context.semanticColors.textSecondary,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          isUpdating
              ? const SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  ),
                )
              : CustomMiniSwitch(
                  value: isActive,
                  onChanged: (value) => _onAccountActiveChanged(context, value),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = <String>[
      'تعديل ملفي الشخصي',
      'مناطق عملي',
      'موقع بدء المهمة',
      'أوقات العمل',
      // 'سجل المعاملات',
      'الدعم والمساعدة',
      'التقييمات والتعليقات',
    ];
    const subtitles = <String>[
      'لتعديل بيانات العرض',
      'يمكنك إدارة أماكن عملك',
      'للمساعدة على حساب تكلفة التنقل',
      'يمكنك تعديل أوقات عملك',
      // 'يمكنك تتبع أدائك',
      'التواصل مع الدعم الفني',
      'للاطلاع على تقييمات العملاء وتعليقاتهم',
    ];
    const images = <IconData>[
      Icons.person,
      Icons.location_on_outlined,
      Icons.flag_outlined,
      Icons.alarm,
      // Icons.signal_cellular_alt,
      Icons.headphones,
      Icons.star_outline_rounded,
    ];

    final colors = <Color>[
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      context.semanticColors.info,
      context.semanticColors.warning,
      Theme.of(context).colorScheme.secondary,
      context.semanticColors.warning,
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
                padding: AppSpace.pagePadding(context).add(
                  const EdgeInsetsDirectional.symmetric(vertical: AppSpace.md),
                ),
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final profileBloc = context.read<ProfileBloc>();
                        return SectionCard(
                          containerColor: context.semanticColors.infoContainer,
                          title: 'المحفظة والإحصائيات',
                          image: Icons.account_balance_wallet_outlined,
                          imageColor: context.semanticColors.info,
                          subtitle: 'الأرباح والحجوزات والملخص المالي',
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
                    const SizedBox(height: AppSpace.lg),
                    const AppSectionHeader(title: 'إدارة الحساب'),
                    const SizedBox(height: AppSpace.sm),
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
                                  /*
                                  : i == 4
                                  ? () {
                                      context.pushRoute('/transactionhistory');
                                    } 
                                  */
                                  : i == 4
                                  ? () async {
                                      await launchSupportWhatsApp(context);
                                    }
                                  : () {
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => BlocProvider.value(
                                            value: profileBloc,
                                            child: const WorkerReviewsScreen(),
                                          ),
                                        ),
                                      );
                                    },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        return _buildAccountActiveToggle(context, state);
                      },
                    ),
                    const SizedBox(height: AppSpace.md),
                    AppButton(
                      label: 'تسجيل الخروج',
                      icon: Icons.logout_rounded,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => _logout(context),
                    ),
                    const SizedBox(height: AppSpace.md),
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
  final ValueChanged<bool>? onChanged;

  @override
  State<CustomMiniSwitch> createState() => _CustomMiniSwitchState();
}

class _CustomMiniSwitchState extends State<CustomMiniSwitch> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'تفعيل الحساب',
      toggled: widget.value,
      enabled: widget.onChanged != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: Switch.adaptive(
            value: widget.value,
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}
