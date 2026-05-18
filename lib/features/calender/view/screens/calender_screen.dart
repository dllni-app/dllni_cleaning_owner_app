import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/calender/view/manager/calender_notifier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../orders/view/manager/bloc/orders_bloc.dart';
import '../widgets/calender_app_bar.dart';
import '../widgets/calender_order_card.dart';
import '../widgets/week_calender.dart';

class CalenderScreen extends StatelessWidget {
  CalenderScreen({super.key});

  final CalenderNotifier calenderNotifier = CalenderNotifier();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrdersBloc>(
      create: (context) =>
          getIt<OrdersBloc>()
            ..add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, scheduledDate: DateFormat('yyyy-MM-dd').format(DateTime.now())))),
      child: SafeArea(
        child: Stack(
          children: [
            Container(
              color: context.primary,
              child: Column(
                children: [
                  SizedBox(height: 100),
                  WeekCalendar(calenderNotifier: calenderNotifier),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.keyboard_arrow_down_rounded, size: 40, color: context.onPrimary)],
                  ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CalenderAppBar(),
                ClipPath(
                  clipper: TopNotchClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                      color: context.surface,
                    ),
                    width: context.width,
                    height: context.height * .55,
                    padding: EdgeInsetsDirectional.only(start: 16, end: 16, top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder(
                          builder: (context, date, _) => AppText.labelSmall(date),
                          valueListenable: calenderNotifier.selectedDate,
                        ),
                        Expanded(
                          child: BlocBuilder<OrdersBloc, OrdersState>(
                            buildWhen: (previous, current) => previous.ordersUsecase != current.ordersUsecase,
                            builder: (context, state) {
                              return state.ordersUsecase!.builder(
                                loadingWidget: Padding(
                                  padding: EdgeInsetsDirectional.only(top: 40),
                                  child: Center(child: CircularProgressIndicator.adaptive()),
                                ),
                                emptyWidget: Center(child: AppText.labelMedium('لا يوجد مهام', fontWeight: FontWeight.w400)),
                                successWidget: () {
                                  return ListView.separated(
                                    padding: EdgeInsetsDirectional.symmetric(vertical: 10),
                                    itemBuilder: (context, index) {
                                      if (state.ordersUsecase!.length <= index) {
                                        if (state.ordersUsecase!.length == index) {
                                          context.read<OrdersBloc>().add(
                                            FetchOrdersUsecaseEvent(
                                              isReload: false,
                                              params: FetchOrdersUsecaseParams(page: state.ordersUsecase!.pageNumber),
                                            ),
                                          );
                                        }
                                        return SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 3)),
                                        );
                                      }
                                      return CalenderOrderCard(date: state.ordersUsecase!.list[index], index: index,);
                                    },
                                    separatorBuilder: (context, index) => SizedBox(height: 16),
                                    itemCount: state.ordersUsecase!.listLength(1),
                                  );
                                },
                                onTapRetry: () {
                                  context.read<OrdersBloc>().add(
                                    FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, status: 'worker_assigned'), isReload: true),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TopNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    const notchWidth = 50.0;
    const notchDepth = 60.0;

    path.moveTo(0, 0);

    path.lineTo(size.width / 2 - notchWidth, 0);

    path.quadraticBezierTo(size.width / 2, notchDepth, size.width / 2 + notchWidth, 0);

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
