import 'package:common_package/common_package.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

import '../manager/bloc/profile_bloc.dart';

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.primary,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(16), bottomLeft: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(27), offset: Offset(0, -2), blurRadius: 12, spreadRadius: 0)],
      ),
      width: context.width,
      height: 100,
      padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          switch (state.workerProfileUsecaseStatus) {
            case null:
              return failedWidget(context);
            case BlocStatus.failed:
              return failedWidget(context);
            case BlocStatus.success:
              return Row(
                children: [
                  CircleAvatar(radius: 30, backgroundImage: NetworkImage('image'), backgroundColor: context.onPrimaryContainer),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelMedium(
                          state.workerProfileUsecase?.data?.user?.name ?? '-',
                          color: context.onPrimary,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.start,
                        ),
                        SizedBox(height: 12),
                        AppText.labelMedium(
                          state.workerProfileUsecase?.data?.user?.id == null ? '-' : state.workerProfileUsecase!.data!.user!.id.toString(),
                          color: context.onPrimary,
                          fontWeight: FontWeight.w500,
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            case BlocStatus.loading:
              return loadingWidget(context);
            case BlocStatus.init:
              return loadingWidget(context);
          }
        },
      ),
    );
  }

  loadingWidget(BuildContext context) => Row(
    children: [
      Shimmer.fromColors(
        baseColor: context.surface,
        highlightColor: context.primary,
        child: CircleAvatar(radius: 30, backgroundColor: context.onPrimaryContainer),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Shimmer.fromColors(
              baseColor: context.surface,
              highlightColor: context.primary,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: context.onPrimary),
                height: 10,
                width: 60,
              ),
            ),
            SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: context.surface,
              highlightColor: context.primary,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: context.onPrimary),
                height: 10,
                width: 100,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  failedWidget(BuildContext context) => Row(
    children: [
      CircleAvatar(
        radius: 30,
        backgroundColor: context.onPrimaryContainer,
        child: AppText.labelLarge('n', fontWeight: FontWeight.bold),
      ),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.labelMedium('-', color: context.onPrimary, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
            SizedBox(height: 12),
            AppText.labelMedium('-', color: context.onPrimary, fontWeight: FontWeight.w500, textAlign: TextAlign.start),
          ],
        ),
      ),
    ],
  );
}
