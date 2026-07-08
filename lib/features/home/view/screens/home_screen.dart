import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/cleaning_realtime_contract.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/pusher_manager.dart';
import 'package:dllni_cleaninig_owner_app/core/realtime/worker_realtime_orders_sync.dart';
import 'package:dllni_cleaninig_owner_app/core/widgets/order_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/widgets/today_overview_card.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_worker_profile_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/helpers/worker_profile_completeness_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';
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

enum HomeOrdersTab { newOrders, todayOrders }

extension HomeOrdersTabX on HomeOrdersTab {
  String get label => switch (this) {
        HomeOrdersTab.newOrders => 'طلبات جديدة',
        HomeOrdersTab.todayOrders => 'طلبات اليوم',
      };

  String get emptyMessage => switch (this) {
        HomeOrdersTab.newOrders => 'لا توجد طلبات جديدة',
        HomeOrdersTab.todayOrders => 'لا توجد طلبات اليوم',
      };
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final Set<String> _homePusherEvents =
      CleaningRealtimeContract.expandEventFilter(const <String>{
    CleaningRealtimeContract.trackingUpdated,
    CleaningRealtimeContract.teamUpdated,
    CleaningRealtimeContract.bookingCreated,
    CleaningRealtimeContract.workerArrived,
    CleaningRealtimeContract.awaitingStartVerification,
    CleaningRealtimeContract.arrivalVerified,
    CleaningRealtimeContract.awaitingWorkerStartConfirmation,
    CleaningRealtimeContract.awaitingCustomerCompletion,
    CleaningRealtimeContract.completionDecisionMade,
    CleaningRealtimeContract.serviceExtensionRequested,
  });

  FetchWorkerProfileUsecaseModel? user;
  bool _isIncompleteDialogOpen = false;
  late final OrdersBloc _ordersBloc;
  late final HomeBloc _homeBloc;
  late final ProfileBloc _profileBloc;
  final PusherManager _pusherManager = getIt<PusherManager>();

  RealtimeListenerHandle? _workerRealtimeHandle;
  StreamSubscription<RemoteMessage>? _fcmForegroundSubscription;
  int? _workerId;
  HomeOrdersTab _selectedHomeOrdersTab = HomeOrdersTab.newOrders;
  int _homeOrdersCurrentPage = 1;

  String get _todayScheduledDate =>
      DateFormat('yyyy-MM-dd', 'en').format(DateTime.now());

  FetchOrdersUsecaseParams _homeOrdersFetchParams({int page = 1}) {
    return switch (_selectedHomeOrdersTab) {
      HomeOrdersTab.newOrders => FetchOrdersUsecaseParams(
          page: page,
          status: CleaningBookingStatus.pending,
        ),
      HomeOrdersTab.todayOrders => FetchOrdersUsecaseParams(
          page: page,
          status: CleaningBookingStatus.workerAssigned,
          scheduledDate: _todayScheduledDate,
        ),
    };
  }

  void _fetchOrdersForSelectedTab({
    bool isReload = false,
    bool silent = false,
  }) {
    final page = isReload ? _homeOrdersCurrentPage : 1;
    _ordersBloc.add(
      FetchOrdersUsecaseEvent(
        params: _homeOrdersFetchParams(page: page),
        isReload: isReload,
        silent: silent,
      ),
    );
  }

  void _onHomeOrdersTabSelected(HomeOrdersTab tab) {
    if (_selectedHomeOrdersTab == tab) return;
    setState(() => _selectedHomeOrdersTab = tab);
    _homeOrdersCurrentPage = 1;
    _fetchOrdersForSelectedTab(isReload: true);
  }

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
    _ordersBloc = getIt<OrdersBloc>();
    _fetchOrdersForSelectedTab();
    _profileBloc = getIt<ProfileBloc>()
      ..add(
        FetchWorkerProfileUsecaseEvent(
          params: FetchWorkerProfileUsecaseParams(),
        ),
      );
    _workerId = _resolveWorkerId();
    unawaited(_bindWorkerRealtimeListener());
    _fcmForegroundSubscription =
        FirebaseMessaging.onMessage.listen(_onForegroundPushMessage);
  }

  int? _resolveWorkerId() {
    final profileWorkerId = user?.data?.id;
    if (profileWorkerId != null && profileWorkerId > 0) {
      return profileWorkerId;
    }

    final raw = SharedPreferencesHelper.getData(key: 'worker_id');
    if (raw is num && raw.toInt() > 0) return raw.toInt();
    final parsed = int.tryParse('$raw');
    if (parsed != null && parsed > 0) return parsed;

    return null;
  }

  String get _workerChannelName {
    final workerId = _workerId;
    if (workerId == null || workerId <= 0) return '';
    return '${CleaningRealtimeContract.workerChannelPrefix}$workerId';
  }

  Future<void> _bindWorkerRealtimeListener() async {
    final workerId = _resolveWorkerId();
    if (workerId == null || workerId <= 0) {
      developer.log('[Home] skip pusher bind: worker_id missing');
      return;
    }

    if (_workerId == workerId && _workerRealtimeHandle != null) return;
    _workerId = workerId;

    await _workerRealtimeHandle?.dispose();
    _workerRealtimeHandle = null;

    await _pusherManager.ensureInitialized();
    if (!mounted) return;

    final channelName = _workerChannelName;
    developer.log('[Home] subscribe pusher => $channelName');

    final handle = await _pusherManager.listen(
      channelName: channelName,
      eventNames: _homePusherEvents,
      onEvent: (event) {
        _onWorkerPusherEvent(event.eventName, event.payload);
      },
      onChannelError: (error) {
        if (!mounted || error.statusCode != 403) return;
        _refreshHomeData(source: 'pusher_auth_403');
      },
    );

    if (!mounted) {
      await handle.dispose();
      return;
    }

    _workerRealtimeHandle = handle;
    developer.log('[Home] pusher listener ready on $channelName');
  }

  void _onWorkerPusherEvent(String eventName, Map<String, dynamic> payload) {
    if (!mounted) return;

    PusherServiceLogger.event(
      _workerChannelName,
      eventName,
      payload,
      eventHandledAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    if (CleaningRealtimeContract.isLocationEvent(eventName)) return;

    final hasBookingId =
        CleaningRealtimeContract.extractBookingId(payload) != null;
    final canSyncVisiblePendingList =
        _selectedHomeOrdersTab == HomeOrdersTab.newOrders && hasBookingId;

    WorkerRealtimeOrdersSync.dispatchSync(
      bloc: _ordersBloc,
      eventName: eventName,
      payload: payload,
      applyToPendingList: _selectedHomeOrdersTab == HomeOrdersTab.newOrders,
    );

    if (canSyncVisiblePendingList) {
      _refreshHomeSummary(source: eventName);
    } else {
      _refreshHomeData(source: eventName);
    }
  }

  void _onForegroundPushMessage(RemoteMessage message) {
    if (!mounted) return;

    developer.log(
      '[Home] FCM foreground => data=${message.data} '
      'title=${message.notification?.title}',
    );

    _refreshHomeData(source: 'fcm_foreground');
  }

  void _refreshHomeSummary({required String source}) {
    if (!mounted) return;
    developer.log('[Home] summary refresh triggered by $source');
    _homeBloc.add(
      FetchHomePageUsecaseEvent(
        params: FetchHomePageUsecaseParams(),
        silent: true,
      ),
    );
  }

  void _refreshHomeData({required String source}) {
    if (!mounted) return;

    developer.log('[Home] refresh triggered by $source');

    _homeBloc.add(
      FetchHomePageUsecaseEvent(
        params: FetchHomePageUsecaseParams(),
        silent: true,
      ),
    );
    _fetchOrdersForSelectedTab(isReload: true, silent: true);
  }

  void _dispatchHomeRefresh({bool isReload = true, bool silent = false}) {
    _homeBloc.add(
      FetchHomePageUsecaseEvent(
        params: FetchHomePageUsecaseParams(),
        silent: silent,
      ),
    );
    _fetchOrdersForSelectedTab(isReload: isReload, silent: silent);
    _profileBloc.add(
      FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams()),
    );
  }

  Future<void> _refreshHomeScreen() async {
    _dispatchHomeRefresh(isReload: true);
  }

  @override
  void dispose() {
    unawaited(_fcmForegroundSubscription?.cancel());
    _fcmForegroundSubscription = null;
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

  Future<void> _cacheProfileWorkerId(ProfileState state) async {
    final workerId = state.workerProfileUsecase?.data?.id;
    if (workerId == null || workerId <= 0) return;
    await SharedPreferencesHelper.saveData(key: 'worker_id', value: workerId);
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
                current.workerProfileUsecaseStatus ||
            previous.workerProfileUsecase?.data?.id !=
                current.workerProfileUsecase?.data?.id,
        listener: (context, state) {
          _maybePromptIncompleteData(state);
          if (state.workerProfileUsecaseStatus == BlocStatus.success) {
            user = state.workerProfileUsecase;
            unawaited(_cacheProfileWorkerId(state));
            unawaited(_bindWorkerRealtimeListener());
          }
        },
        child: BlocListener<OrdersBloc, OrdersState>(
          listenWhen: (previous, current) =>
              previous.ordersUsecase != current.ordersUsecase,
          listener: (context, state) {
            if (state.ordersUsecase?.status != BlocStatus.success) return;
            _homeOrdersCurrentPage = context
                .read<OrdersBloc>()
                .lastAppliedOrdersListFilter
                .page;
          },
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
                          16.verticalSpace,
                          _HomeOrdersSection(
                            selectedTab: _selectedHomeOrdersTab,
                            onTabSelected: _onHomeOrdersTabSelected,
                            paramsForPage: (page) =>
                                _homeOrdersFetchParams(page: page),
                            onRetry: () =>
                                _fetchOrdersForSelectedTab(isReload: true),
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
      ),
    );
  }
}

class _HomeOrdersSection extends StatelessWidget {
  const _HomeOrdersSection({
    required this.selectedTab,
    required this.onTabSelected,
    required this.paramsForPage,
    required this.onRetry,
  });

  final HomeOrdersTab selectedTab;
  final ValueChanged<HomeOrdersTab> onTabSelected;
  final FetchOrdersUsecaseParams Function(int page) paramsForPage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      buildWhen: (previous, current) =>
          previous.ordersUsecase != current.ordersUsecase,
      builder: (context, state) {
        final orders = state.ordersUsecase!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HomeOrdersTabSelector(
              selectedTab: selectedTab,
              onChanged: onTabSelected,
            ),
            8.verticalSpace,
            orders.builder(
              loadingWidget: Padding(
                padding: EdgeInsetsDirectional.only(top: 40.h),
                child: const Center(child: CircularProgressIndicator.adaptive()),
              ),
              emptyWidget: AppText.labelMedium(
                selectedTab.emptyMessage,
                fontWeight: FontWeight.w400,
              ),
              successWidget: () {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.listLength(1),
                  separatorBuilder: (context, index) => 16.verticalSpace,
                  itemBuilder: (context, index) {
                    if (orders.length <= index) {
                      if (orders.length == index) {
                        context.read<OrdersBloc>().add(
                              FetchOrdersUsecaseEvent(
                                isReload: false,
                                params: paramsForPage(orders.pageNumber),
                              ),
                            );
                      }

                      return SizedBox(
                        width: 30.w,
                        height: 30.h,
                        child: const FittedBox(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 3,
                          ),
                        ),
                      );
                    }

                    final item = orders.list[index];

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: OrderCard(
                        key: ValueKey(item.id),
                        data: item,
                        bloc: context.read<OrdersBloc>(),
                        index: index,
                      ),
                    );
                  },
                );
              },
              failedWidget: AppText.labelLarge(
                ErrorMessageFormatter.format(
                  state.errorMessage,
                  fallback: 'حدث خطأ ما',
                ),
                color: context.error,
              ),
              onTapRetry: onRetry,
            ),
          ],
        );
      },
    );
  }
}

class _HomeOrdersTabSelector extends StatelessWidget {
  const _HomeOrdersTabSelector({
    required this.selectedTab,
    required this.onChanged,
  });

  final HomeOrdersTab selectedTab;
  final ValueChanged<HomeOrdersTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: HomeOrdersTab.values.map((tab) {
        final isSelected = selectedTab == tab;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(tab),
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: 8.h),
              child: Column(
                children: [
                  AppText.labelLarge(
                    tab.label,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? context.primary
                        : context.colorScheme.outline,
                  ),
                  6.verticalSpace,
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isSelected ? context.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}
