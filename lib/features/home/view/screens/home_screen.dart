import 'dart:async';
import 'dart:convert';

import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/order_card.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/today_overview_card.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/helpers/worker_profile_completeness_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../main/view/screens/main_screen.dart';
import '../../../orders/data/models/cleaning_booking_status.dart';
import '../../../orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import '../../../orders/view/manager/bloc/orders_bloc.dart';
import '../../../profile/view/manager/bloc/profile_bloc.dart';
import '../../../profile/view/screens/wallet_screen.dart';
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
  static const Duration _realtimeRefreshDebounce = Duration(milliseconds: 150);

  FetchWorkerProfileUsecaseModel? user;
  bool _isIncompleteDialogOpen = false;
  late final OrdersBloc _ordersBloc;
  late final HomeBloc _homeBloc;
  late final ProfileBloc _profileBloc;
  final PusherManager _pusherManager = getIt<PusherManager>();
  RealtimeListenerHandle? _workerRealtimeHandle;
  Timer? _realtimeRefreshTimer;
  final List<({String eventName, Map<String, dynamic> payload})>
  _pendingOrderSyncQueue = [];
  int? _workerId;

  @override
  void initState() {
    super.initState();
    final data = SharedPreferencesHelper.getData(key: 'user');
    if (data != null) {
      user = fetchWorkerProfileUsecaseModelFromJson(
        data is String ? json.decode(data) : data,
      );
    }
    _homeBloc = getIt<HomeBloc>()
      ..add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()));
    _ordersBloc = getIt<OrdersBloc>()
      ..add(
        FetchOrdersUsecaseEvent(
          params: FetchOrdersUsecaseParams(
            page: 1,
            status: CleaningBookingStatus.pending,
          ),
        ),
      );
    _profileBloc = getIt<ProfileBloc>()
      ..add(
        FetchWorkerProfileUsecaseEvent(
          params: FetchWorkerProfileUsecaseParams(),
        ),
      );
    _workerId = _resolveWorkerId();
    unawaited(_bindWorkerRealtimeListener());
  }

  int? _resolveWorkerId() {
    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  Future<void> _bindWorkerRealtimeListener() async {
    final workerId = _workerId;
    if (workerId == null || workerId <= 0) return;
    final handle = await _pusherManager.listen(
      channelName: '${CleaningRealtimeContract.workerChannelPrefix}$workerId',
      onEvent: (event) {
        if (!mounted) return;
        final hasBookingId =
            CleaningRealtimeContract.extractBookingId(event.payload) != null;
        final shouldSync =
            CleaningRealtimeContract.shouldRefreshPendingOrdersForWorkerEvent(
              event.eventName,
              event.payload,
            );
        if (!shouldSync &&
            (!hasBookingId ||
                CleaningRealtimeContract.isLocationEvent(event.eventName))) {
          return;
        }
        _schedulePendingOrderSync(
          eventName: event.eventName,
          payload: event.payload,
        );
      },
      onChannelError: (error) {
        if (!mounted || error.statusCode != 403) return;
        _schedulePendingOrderSync(eventName: '', payload: const {});
      },
    );
    if (!mounted) {
      await handle.dispose();
      return;
    }
    _workerRealtimeHandle = handle;
  }

  void _dispatchHomeRefresh({bool isReload = true, bool silent = false}) {
    _homeBloc.add(
      FetchHomePageUsecaseEvent(
        params: FetchHomePageUsecaseParams(),
        silent: silent,
      ),
    );
    _ordersBloc.add(
      FetchOrdersUsecaseEvent(
        params: FetchOrdersUsecaseParams(
          page: 1,
          status: CleaningBookingStatus.pending,
        ),
        isReload: isReload,
        silent: silent,
      ),
    );
    _profileBloc.add(
      FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams()),
    );
  }

  Future<void> _refreshHomeScreen() async {
    final homeCompletion = _homeBloc.stream
        .skip(1)
        .firstWhere(
          (state) => state.homePageUsecaseStatus != BlocStatus.loading,
        );
    final ordersCompletion = _ordersBloc.stream
        .skip(1)
        .firstWhere(
          (state) => state.ordersUsecase!.status != BlocStatus.loading,
        );
    final profileCompletion = _profileBloc.stream
        .skip(1)
        .firstWhere(
          (state) => state.workerProfileUsecaseStatus != BlocStatus.loading,
        );

    _dispatchHomeRefresh(isReload: true);

    await Future.wait([homeCompletion, ordersCompletion, profileCompletion]);
  }

  void _schedulePendingOrderSync({
    required String eventName,
    required Map<String, dynamic> payload,
  }) {
    _pendingOrderSyncQueue.add((eventName: eventName, payload: payload));
    _realtimeRefreshTimer?.cancel();
    _realtimeRefreshTimer = Timer(_realtimeRefreshDebounce, () {
      if (!mounted) return;
      final queued = List.of(_pendingOrderSyncQueue);
      _pendingOrderSyncQueue.clear();
      for (final request in queued) {
        _ordersBloc.add(
          SyncPendingOrderFromRealtimeEvent(
            eventName: request.eventName,
            payload: request.payload,
          ),
        );
      }
      _homeBloc.add(
        FetchHomePageUsecaseEvent(
          params: FetchHomePageUsecaseParams(),
          silent: true,
        ),
      );
    });
  }

  @override
  void dispose() {
    _realtimeRefreshTimer?.cancel();
    _pendingOrderSyncQueue.clear();
    final handle = _workerRealtimeHandle;
    _workerRealtimeHandle = null;
    unawaited(handle?.dispose());
    _homeBloc.close();
    _ordersBloc.close();
    _profileBloc.close();
    super.dispose();
  }

  Future<void> _showIncompleteDataDialog(List<String> missingSectionsAr) async {
    if (!mounted || _isIncompleteDialogOpen) return;
    _isIncompleteDialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return IncompleteProfileWarningDialog(
          missingSectionsAr: missingSectionsAr,
          onLater: () => Navigator.of(dialogContext).pop(),
          onCompleteNow: () {
            Navigator.of(dialogContext).pop();
            if (!mounted) return;
            context.pushRouteAndRemoveUntil(
              '/main',
              arguments: MainScreenParam(returnedPageIndex: 3),
            );
          },
        );
      },
    );

    _isIncompleteDialogOpen = false;
  }

  void _maybePromptIncompleteData(ProfileState state) {
    if (state.workerProfileUsecaseStatus != BlocStatus.success) return;

    final completeness = evaluateWorkerProfileCompleteness(
      state.workerProfileUsecase?.data,
    );
    if (!WorkerProfileCompletenessPromptGate.consumeShouldPrompt(
      completeness,
    )) {
      return;
    }
    _showIncompleteDataDialog(completeness.missingSectionsAr);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>.value(value: _homeBloc),
        BlocProvider<OrdersBloc>.value(value: _ordersBloc),
        BlocProvider<ProfileBloc>.value(value: _profileBloc),
      ],
      child: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) =>
            previous.workerProfileUsecaseStatus !=
            current.workerProfileUsecaseStatus,
        listener: (context, state) => _maybePromptIncompleteData(state),
        child: SafeArea(
          child: Column(
            children: [
              const HomeAppBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshHomeScreen,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsetsDirectional.only(
                      start: 24.w,
                      end: 24.w,
                      bottom: 20.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        16.verticalSpace,
                        AppText.labelLarge(
                          'نظرة عامة عن اليوم',
                          fontWeight: FontWeight.w400,
                        ),
                        12.verticalSpace,
                        TodayOverviewCard(),
                        12.verticalSpace,
                        Builder(
                          builder: (innerContext) {
                            return StatisticsRow(
                              onStatisticsTap: () {
                                Navigator.of(innerContext).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => BlocProvider.value(
                                      value: innerContext.read<ProfileBloc>(),
                                      child: const WalletScreen(),
                                    ),
                                  ),
                                );
                              },
                              onStatusTap: (status) {
                                innerContext.pushRouteAndRemoveUntil(
                                  '/main',
                                  arguments: MainScreenParam(
                                    returnedPageIndex: 2,
                                    ordersInitialStatus: status,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        /*12.verticalSpace,
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
                                  ExtensionRequestsSheet.show(context, onChanged: () => context.read<HomeBloc>().add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams())));
                                },
                                child: Padding(
                                  padding: EdgeInsetsDirectional.symmetric(horizontal: 16.w, vertical: 12.h),
                                  child: Row(
                                    children: [
                                      Icon(Icons.more_time, color: context.error),
                                      12.horizontalSpace,
                                      Expanded(child: AppText.labelLarge('طلبات تمديد الوقت ($n)', fontWeight: FontWeight.w500)),
                                      Icon(Icons.chevron_right, color: context.colorScheme.outline),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),*/
                        16.verticalSpace,
                        Row(
                          children: [
                            AppText.labelLarge(
                              'مهام اليوم',
                              fontWeight: FontWeight.w400,
                            ),
                            8.horizontalSpace,
                            CircleAvatar(
                              radius: 10.r,
                              backgroundColor: context.error,
                              child: BlocBuilder<OrdersBloc, OrdersState>(
                                builder: (context, state) {
                                  return AppText.labelSmall(
                                    state.ordersUsecase!.isSuccess
                                        ? state.ordersUsecase!.list.length
                                              .toString()
                                        : '0',
                                    color: context.onError,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        8.verticalSpace,
                        BlocBuilder<OrdersBloc, OrdersState>(
                          buildWhen: (previous, current) =>
                              previous.ordersUsecase != current.ordersUsecase,
                          builder: (context, state) {
                            return state.ordersUsecase!.builder(
                              loadingWidget: Padding(
                                padding: EdgeInsetsDirectional.only(top: 40.h),
                                child: const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                ),
                              ),
                              emptyWidget: AppText.labelMedium(
                                'لا يوجد مهام',
                                fontWeight: FontWeight.w400,
                              ),
                              successWidget: () {
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) => OrderCard(
                                    data: state.ordersUsecase!.list[index],
                                    bloc: context.read<OrdersBloc>(),
                                    index: index,
                                  ),
                                  separatorBuilder: (context, index) =>
                                      16.verticalSpace,
                                  itemCount: state.ordersUsecase!.list.length,
                                );
                              },
                              failedWidget: AppText.labelLarge(
                                state.errorMessage ?? 'حدث خطأ ما',
                                color: context.error,
                              ),
                              onTapRetry: () {
                                context.read<OrdersBloc>().add(
                                  FetchOrdersUsecaseEvent(
                                    params: FetchOrdersUsecaseParams(
                                      page: 1,
                                      status: CleaningBookingStatus.pending,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
