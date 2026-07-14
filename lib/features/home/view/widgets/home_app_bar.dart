import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../profile/view/manager/bloc/profile_bloc.dart';
import '../../../profile/view/screens/notifications_screen.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.onPrimary,
        border: Border(bottom: BorderSide(color: context.primaryContainer, width: 3)),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(24.r), bottomLeft: Radius.circular(24.r)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2.h), blurRadius: 12.r, spreadRadius: 0)],
      ),
      width: context.width,
      height: 70.h,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24.w),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return Row(
            children: [
              state.workerProfileUsecase?.data?.avatar?.url != null
                  ? AppImage.network(
                      state.workerProfileUsecase!.data!.avatar!.url!,
                      borderRadius: BorderRadius.circular(99),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : SizedBox.shrink(),
              8.horizontalSpace,
              Expanded(
                child: AppText.labelMedium(
                  'مرحباً ${state.workerProfileUsecase?.data?.firstName ?? ''}, لنكتشف ماهي مهامك اليوم',
                  color: Color(0xff2C6862),
                  fontWeight: FontWeight.w500,
                  textAlign: TextAlign.start,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final profileBloc = context.read<ProfileBloc>();
                  context.pushRoute(
                    '/notifications',
                    arguments: NotificationsScreenParams(profileBloc: profileBloc),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_none_outlined, color: context.primaryContainer),
                    if (state.unreadNotification != null && state.unreadNotification! > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.onPrimary,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            state.unreadNotification.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
