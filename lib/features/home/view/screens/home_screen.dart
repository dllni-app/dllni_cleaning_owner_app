import 'dart:convert';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/order_card.dart';
import 'package:dllni_cleaninig_owner_app/features/auth/data/models/login_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/today_overview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../orders/view/manager/bloc/orders_bloc.dart';
import '../../domain/usecases/fetch_home_page_usecase_use_case.dart';
import '../manager/bloc/home_bloc.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/statistics_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  LoginUsecaseModel? user;

  @override
  void initState() {
    super.initState();
    user = loginUsecaseModelFromJson(json.decode(SharedPreferencesHelper.getData(key: 'user')));
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
          create: (context) => getIt<OrdersBloc>()..add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'pending'))),
        ),
      ],
      child: SafeArea(
        child: Column(
          children: [
            HomeAppBar(name: user?.user?.name,),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsetsDirectional.only(start: 24, end: 24, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    // WarningContainer(),
                    // SizedBox(height: 24),
                    AppText.labelLarge('نظرة عامة عن اليوم', fontWeight: FontWeight.w400),
                    SizedBox(height: 12),
                    TodayOverviewCard(),
                    SizedBox(height: 12),
                    StatisticsRow(),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        AppText.labelLarge('مهام اليوم', fontWeight: FontWeight.w400),
                        SizedBox(width: 8),
                        CircleAvatar(
                          radius: 10,
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
                    SizedBox(height: 8),
                    BlocBuilder<OrdersBloc, OrdersState>(
                      buildWhen: (previous, current) => previous.ordersUsecase != current.ordersUsecase,
                      builder: (context, state) {
                        return state.ordersUsecase!.builder(
                          loadingWidget: Padding(
                            padding: EdgeInsetsDirectional.only(top: 40),
                            child: Center(child: CircularProgressIndicator.adaptive()),
                          ),
                          emptyWidget: AppText.labelMedium('لا يوجد مهام', fontWeight: FontWeight.w400),
                          successWidget: () {
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) =>
                                  OrderCard(date: state.ordersUsecase!.list[index], isInHome: true, bloc: context.read<OrdersBloc>()),
                              separatorBuilder: (context, index) => SizedBox(height: 16),
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
