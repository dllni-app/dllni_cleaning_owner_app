import 'dart:convert';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/order_card.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/today_overview_card.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../orders/view/manager/bloc/orders_bloc.dart';
import '../../../profile/view/manager/bloc/profile_bloc.dart';
import '../../domain/usecases/fetch_home_page_usecase_use_case.dart';
import '../../../orders/view/widgets/extension_requests_sheet.dart';
import '../manager/bloc/home_bloc.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/statistics_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FetchWorkerProfileUsecaseModel? user;

  @override
  void initState() {
    super.initState();
    final data = SharedPreferencesHelper.getData(key: 'user');
    if (data != null) {
      user = fetchWorkerProfileUsecaseModelFromJson(data is String ? json.decode(data) : data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          lazy: false,
          create: (context) => getIt<HomeBloc>()..add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams())),
        ),
        BlocProvider<OrdersBloc>(
          lazy: false,
          create: (context) =>
              getIt<OrdersBloc>()..add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'worker_assigned'))),
        ),
        BlocProvider<ProfileBloc>(
          lazy: false,
          create: (context) => getIt<ProfileBloc>()..add(FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams())),
        ),
      ],
      child: SafeArea(
        child: Column(
          children: [
            HomeAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(start: 24.w, end: 24.w, bottom: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    16.verticalSpace,
                    // WarningContainer(),
                    // SizedBox(height: 24),
                    AppText.labelLarge('نظرة عامة عن اليوم', fontWeight: FontWeight.w400),
                    12.verticalSpace,
                    TodayOverviewCard(),
                    12.verticalSpace,
                    StatisticsRow(),
                    12.verticalSpace,
                    BlocBuilder<HomeBloc, HomeState>(
                      builder: (context, homeState) {
                        final n = homeState.homePageUsecase?.pendingExtensionRequestsCount ?? 0;
                        if (homeState.homePageUsecaseStatus != BlocStatus.success || n <= 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Material(
                            color: context.colorScheme.errorContainer.withAlpha(100),
                            borderRadius: BorderRadius.circular(12.r),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.r),
                              onTap: () {
                                ExtensionRequestsSheet.show(
                                  context,
                                  onChanged: () => context.read<HomeBloc>().add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams())),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 12.h),
                                child: Row(
                                  children: [
                                    Icon(Icons.more_time, color: context.error),
                                    12.horizontalSpace,
                                    Expanded(child: AppText.labelLarge('طلبات تمديد الوقت ($n)', fontWeight: FontWeight.w500)),
                                    Icon(Icons.chevron_left, color: context.colorScheme.outline),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    16.verticalSpace,
                    Row(
                      children: [
                        AppText.labelLarge('مهام اليوم', fontWeight: FontWeight.w400),
                        8.horizontalSpace,
                        CircleAvatar(
                          radius: 10.r,
                          backgroundColor: context.error,
                          child: BlocBuilder<OrdersBloc, OrdersState>(
                            builder: (context, state) {
                              return AppText.labelSmall(
                                state.ordersUsecase!.isSuccess ? state.ordersUsecase!.list.length.toString() : '0',
                                color: context.onError,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    8.verticalSpace,
                    BlocBuilder<OrdersBloc, OrdersState>(
                      buildWhen: (previous, current) => previous.ordersUsecase != current.ordersUsecase,
                      builder: (context, state) {
                        return state.ordersUsecase!.builder(
                          loadingWidget: Padding(
                            padding: EdgeInsetsDirectional.only(top: 40.h),
                            child: Center(child: CircularProgressIndicator.adaptive()),
                          ),
                          emptyWidget: AppText.labelMedium('لا يوجد مهام', fontWeight: FontWeight.w400),
                          successWidget: () {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) => OrderCard(
                                date: state.ordersUsecase!.list[index],
                                isInHome: true,
                                bloc: context.read<OrdersBloc>(),
                                index: index,
                                orderStatus: OrderStatus.workerAssigned,
                              ),
                              separatorBuilder: (context, index) => 16.verticalSpace,
                              itemCount: state.ordersUsecase!.list.length,
                            );
                          },
                          failedWidget: AppText.labelLarge(state.errorMessage ?? 'حدث خطا ما', color: context.error),
                          onTapRetry: () {
                            context.read<OrdersBloc>().add(
                              FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'worker_assigned')),
                            );
                          },
                        );
                      },
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
