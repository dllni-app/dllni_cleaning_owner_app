import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/update_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../generated/assets.dart';
import '../manager/bloc/profile_bloc.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/statistics_line_chart.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final List<String> titles = ['تعديل ملفي الشخصي', 'مناطق عملي', 'أوقات العمل', 'سجل المعاملات'];
    final List<String> images = [Assets.imagesProfileUser, Assets.imagesProfileLocation, Assets.imagesProfileClock, Assets.imagesProfileSignal];

    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (context) => getIt<ProfileBloc>()..add(FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams())),
      child: SafeArea(
        child: Column(
          children: [
            ProfileAppBar(),
            SingleChildScrollView(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 14),
              child: Column(
                children: [
                  StatisticsLineChart(),
                  SizedBox(height: 24),
                  Column(
                    spacing: 15,
                    children: List.generate(
                      titles.length,
                      (i) => BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, state) {
                          return sectionContainer(
                            images[i],
                            titles[i],
                            context,
                            i == 0
                                ? () {
                                    context.pushRoute(
                                      '/updateprofile',
                                      arguments: UpdateProfileScreenParams(
                                        name: state.workerProfileUsecase!.data!.user!.name!,
                                        email: state.workerProfileUsecase?.data?.user?.email,
                                        phone: state.workerProfileUsecase?.data?.user?.phone,
                                        bio: state.workerProfileUsecase?.data?.bio,
                                        city: state.workerProfileUsecase?.data?.homeAddress,
                                      ),
                                    );
                                  }
                                : i == 1
                                ? () {}
                                : i == 2
                                ? () {
                                    context.pushRoute('/workingtime', arguments: state.workerProfileUsecase!.data!.defaultWorkingHours!);
                                  }
                                : () {
                                    context.pushRoute('/transactionhistory');
                                  },
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      AppText.labelLarge('حالة الحساب', color: context.primary, fontWeight: FontWeight.w500),
                      SizedBox(width: 16),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionContainer(String image, String title, BuildContext context, Function() onTap) => InkWell(
    borderRadius: BorderRadius.circular(24),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(color: Color(0xffE9EBEF), borderRadius: BorderRadius.circular(24)),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          AppImage.asset(image, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: AppText.labelLarge(title, textAlign: TextAlign.start, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(width: 16),
          Icon(Icons.arrow_forward_ios, size: 18, color: context.primary),
        ],
      ),
    ),
  );
}

class CustomMiniSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const CustomMiniSwitch({super.key, required this.value, required this.onChanged});

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
        width: 46,
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: widget.value ? Colors.green.withAlpha(63) : Colors.grey.shade300, borderRadius: BorderRadius.circular(20)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: widget.value ? Colors.green : Colors.grey, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
