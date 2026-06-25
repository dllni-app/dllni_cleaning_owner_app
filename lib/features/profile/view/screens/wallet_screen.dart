import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/home/domain/usecases/fetch_home_page_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/manager/bloc/home_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/cleaning_booking_status.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/data/models/fetch_orders_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/domain/usecases/fetch_orders_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/manager/bloc/orders_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_deposit_transactions_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_deposit_transactions_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  static const int ordersPerPage = 10;
  static const int transfersPerPage = 20;

  @override
  State<WalletScreen> createState() => _WalletScreenState();

  static String resolveCurrencyLabel(String? rawCurrency) {
    final currency = rawCurrency?.trim().toUpperCase();
    if (currency == null || currency.isEmpty || currency == 'SYP') {
      return 'ل.س';
    }
    return currency;
  }

  static String formatAmount(num value) {
    final fixed = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final groupedWhole = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

    if (parts.length == 1) return groupedWhole;
    final fraction = parts[1].replaceAll(RegExp(r'0+$'), '');
    if (fraction.isEmpty) return groupedWhole;
    return '$groupedWhole.$fraction';
  }

  static String formatScheduledDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;
    return DateFormat('yyyy-MM-dd', 'en').format(parsed);
  }

  static String formatScheduledTime(String? rawTime) {
    return CleaningArabicTimeFormatter.formatScheduledTime(rawTime);
  }

  static String formatDateTime(String? rawDateTime) {
    return CleaningArabicTimeFormatter.formatDateTime(rawDateTime);
  }
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profileBloc = context.read<ProfileBloc>();
      profileBloc.add(FetchDepositAccountEvent());
      profileBloc.add(FetchDepositTransactionsEvent(params: FetchDepositTransactionsParams(page: 1, perPage: WalletScreen.transfersPerPage), isReload: true, clearTypeFilter: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(lazy: false, create: (_) => getIt<HomeBloc>()..add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()))),
        BlocProvider<OrdersBloc>(
          lazy: false,
          create: (_) => getIt<OrdersBloc>()
            ..add(
              FetchOrdersUsecaseEvent(
                params: FetchOrdersUsecaseParams(page: 1, perPage: WalletScreen.ordersPerPage, status: CleaningBookingStatus.completed),
                isReload: true,
              ),
            ),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xffF3F4F6),
        body: SafeArea(
          child: Column(
            children: [
              const _WalletAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(20.w, 18.h, 20.w, 24.h),
                  child: Column(
                    children: [
                      const _TrustScoreCard(),
                      16.verticalSpace,
                      BlocBuilder<HomeBloc, HomeState>(
                        builder: (context, state) {
                          return _HomeFinanceSection(state: state);
                        },
                      ),
                      16.verticalSpace,
                      const _SecurityDepositSection(),
                      16.verticalSpace,
                      const _HistoryTabsSection(),
                    ],
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

class _WalletAppBar extends StatelessWidget {
  const _WalletAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)),
        border: Border(bottom: BorderSide(color: context.primaryContainer, width: 2)),
      ),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 22.w, vertical: 16.h),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back_ios_new, color: context.primaryContainer),
          ),
          10.horizontalSpace,
          AppText.headlineLarge('احصائياتي', color: context.primaryContainer, fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}

class _TrustScoreCard extends StatelessWidget {
  const _TrustScoreCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => previous.workerProfileUsecaseStatus != current.workerProfileUsecaseStatus || previous.workerProfileUsecase != current.workerProfileUsecase,
      builder: (context, state) {
        final status = state.workerProfileUsecaseStatus;
        final isLoading = status == null || status == BlocStatus.loading || status == BlocStatus.init;
        final trustScore = state.workerProfileUsecase?.data?.trustScore;

        return Container(
          width: context.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xffE5E7EB)),
          ),
          padding: EdgeInsetsDirectional.fromSTEB(16.w, 14.h, 16.w, 14.h),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(color: const Color(0xffA855F7).withAlpha(32), shape: BoxShape.circle),
                child: const Icon(Icons.stars_rounded, color: Color(0xff7E22CE)),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyLarge('نقاط الثقة', fontWeight: FontWeight.w700, color: const Color(0xff111827)),
                    4.verticalSpace,
                    if (isLoading) _LoadingLine(width: 96.w) else AppText.labelLarge('%${trustScore ?? 0} نقاط الثقة', fontWeight: FontWeight.w600, color: const Color(0xff7E22CE)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeFinanceSection extends StatelessWidget {
  const _HomeFinanceSection({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final status = state.homePageUsecaseStatus;
    final model = state.homePageUsecase;
    final isLoading = status == null || status == BlocStatus.loading || status == BlocStatus.init;
    final isFailed = status == BlocStatus.failed;

    final amountSummary = model?.amountSummary;
    final currencyLabel = WalletScreen.resolveCurrencyLabel(amountSummary?.currency);
    final workerAmount = amountSummary?.workerAmount ?? 0;
    final adminAmount = amountSummary?.adminAmount ?? 0;
    final grossInvoicesAmount = amountSummary?.grossInvoicesAmount ?? 0;
    final completedOrdersCount = model?.completedCount ?? 0;

    return Column(
      children: [
        if (isFailed) ...[
          _ErrorBanner(
            message: state.errorMessage ?? 'حدث خطأ ما',
            onRetry: () {
              context.read<HomeBloc>().add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()));
            },
          ),
          16.verticalSpace,
        ],
        _SummaryCard(
          grossInvoicesAmount: WalletScreen.formatAmount(grossInvoicesAmount),
          depositedToAdminAmount: WalletScreen.formatAmount(workerAmount),
          adminProfitAmount: WalletScreen.formatAmount(adminAmount),
          completedOrdersCount: WalletScreen.formatAmount(completedOrdersCount),
          currencyLabel: currencyLabel,
          isLoading: isLoading,
        ),
      ],
    );
  }
}

class _SecurityDepositSection extends StatelessWidget {
  const _SecurityDepositSection();

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xff16A34A);
      case 'insufficient_balance':
        return const Color(0xffDC2626);
      case 'suspended':
        return const Color(0xff7C3AED);
      default:
        return const Color(0xff6B7280);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'insufficient_balance':
        return 'رصيد غير كاف';
      case 'suspended':
        return 'معلق';
      default:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => previous.depositAccountStatus != current.depositAccountStatus || previous.depositAccount != current.depositAccount,
      builder: (context, state) {
        final status = state.depositAccountStatus;
        final isLoading = status == null || status == BlocStatus.loading || status == BlocStatus.init;
        final isFailed = status == BlocStatus.failed;
        final data = state.depositAccount;
        const currency = 'ل.س';

        return Column(
          children: [
            if (isFailed) ...[
              _ErrorBanner(
                message: state.errorMessage ?? 'تعذر تحميل بيانات التأمين',
                onRetry: () {
                  context.read<ProfileBloc>().add(FetchDepositAccountEvent());
                },
              ),
              12.verticalSpace,
            ],
            Container(
              width: context.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xffE5E7EB)),
              ),
              padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppText.bodyLarge('حالة مبلغ التأمين', color: const Color(0xff111827), fontWeight: FontWeight.w700),
                      ),
                      if (!isLoading)
                        Container(
                          padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(color: _statusColor(data?.status ?? '').withAlpha(25), borderRadius: BorderRadius.circular(999.r)),
                          child: AppText.labelMedium(_statusLabel(data?.status ?? ''), color: _statusColor(data?.status ?? ''), fontWeight: FontWeight.w700),
                        )
                      else
                        _LoadingLine(width: 74.w),
                    ],
                  ),
                  12.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          title: 'الرصيد الحالي',
                          value: '${WalletScreen.formatAmount(data?.currentBalance ?? 0)} $currency',
                          accentColor: const Color(0xff0EA5E9),
                          isLoading: isLoading,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _MetricTile(
                          title: 'الحد الأدنى المطلوب',
                          value: '${WalletScreen.formatAmount(data?.minimumRequired ?? 0)} $currency',
                          accentColor: const Color(0xffF59E0B),
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                  10.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          title: 'إجمالي الإيداع',
                          value: '${WalletScreen.formatAmount(data?.depositedTotal ?? 0)} $currency',
                          accentColor: const Color(0xff10B981),
                          isLoading: isLoading,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _MetricTile(
                          title: 'إجمالي السحب',
                          value: '${WalletScreen.formatAmount(data?.withdrawnTotal ?? 0)} $currency',
                          accentColor: const Color(0xffEF4444),
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                  if ((data?.exceedanceAmount ?? 0) > 0) ...[
                    12.verticalSpace,
                    Container(
                      width: context.width,
                      padding: EdgeInsetsDirectional.fromSTEB(10.w, 10.h, 10.w, 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xffFEF2F2),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xffFECACA)),
                      ),
                      child: AppText.labelLarge('مقدار التجاوز: ${WalletScreen.formatAmount(data?.exceedanceAmount ?? 0)} $currency', color: const Color(0xffB91C1C), fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryTabsSection extends StatefulWidget {
  const _HistoryTabsSection();

  @override
  State<_HistoryTabsSection> createState() => _HistoryTabsSectionState();
}

class _HistoryTabsSectionState extends State<_HistoryTabsSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: context.width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xffE5E7EB)),
          ),
          padding: EdgeInsetsDirectional.fromSTEB(10.w, 10.h, 10.w, 10.h),
          child: Row(
            children: [
              Expanded(
                child: _HistoryTabChip(label: 'سجل الطلبات', selected: _selectedIndex == 0, onTap: () => setState(() => _selectedIndex = 0)),
              ),
              8.horizontalSpace,
              Expanded(
                child: _HistoryTabChip(label: 'سجل التحويلات', selected: _selectedIndex == 1, onTap: () => setState(() => _selectedIndex = 1)),
              ),
            ],
          ),
        ),
        12.verticalSpace,
        if (_selectedIndex == 0) const _OrdersHistorySection() else const _TransfersHistorySection(),
      ],
    );
  }
}

class _HistoryTabChip extends StatelessWidget {
  const _HistoryTabChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff1E3A8A) : const Color(0xffF3F4F6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: selected ? const Color(0xff1E3A8A) : const Color(0xffE5E7EB)),
        ),
        alignment: Alignment.center,
        child: AppText.labelLarge(label, color: selected ? Colors.white : const Color(0xff374151), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OrdersHistorySection extends StatelessWidget {
  const _OrdersHistorySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      buildWhen: (previous, current) => previous.ordersUsecase != current.ordersUsecase || previous.errorMessage != current.errorMessage,
      builder: (context, state) {
        final pagination = state.ordersUsecase;
        if (pagination == null) {
          return const _OrdersHistoryLoadingCard();
        }

        final isInitialLoading = pagination.isLoading;
        final isLoadMoreLoading = pagination.status == BlocStatus.loading && pagination.list.isNotEmpty;

        if (isInitialLoading) {
          return const _OrdersHistoryLoadingCard();
        }

        if (pagination.isFailed) {
          return _ErrorBanner(
            message: pagination.errorMessage.isNotEmpty ? pagination.errorMessage : (state.errorMessage ?? 'تعذر تحميل سجل الطلبات'),
            onRetry: () {
              context.read<OrdersBloc>().add(
                FetchOrdersUsecaseEvent(
                  params: FetchOrdersUsecaseParams(page: 1, perPage: WalletScreen.ordersPerPage, status: CleaningBookingStatus.completed),
                  isReload: true,
                ),
              );
            },
          );
        }

        if (pagination.isEmpty) {
          return _HistoryCard(
            title: 'سجل الطلبات',
            listBody: const Center(
              child: Padding(padding: EdgeInsetsDirectional.symmetric(vertical: 24), child: Text('السجل فارغ')),
            ),
            footer: const SizedBox.shrink(),
          );
        }

        return _HistoryCard(
          title: 'سجل الطلبات',
          listBody: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pagination.list.length,
            separatorBuilder: (context, _) => 10.verticalSpace,
            itemBuilder: (context, index) {
              return _OrderHistoryTile(order: pagination.list[index], index: index);
            },
          ),
          footer: !pagination.isEndPage
              ? Padding(
                  padding: EdgeInsetsDirectional.only(top: 12.h),
                  child: SizedBox(
                    width: context.width,
                    child: OutlinedButton(
                      onPressed: isLoadMoreLoading
                          ? null
                          : () {
                              context.read<OrdersBloc>().add(
                                FetchOrdersUsecaseEvent(
                                  params: FetchOrdersUsecaseParams(page: pagination.pageNumber, perPage: WalletScreen.ordersPerPage, status: CleaningBookingStatus.completed),
                                  isReload: false,
                                ),
                              );
                            },
                      child: isLoadMoreLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 2.5)),
                            )
                          : AppText.bodySmall('تحميل المزيد', color: const Color(0xff1E3A8A), fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _TransfersHistorySection extends StatelessWidget {
  const _TransfersHistorySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          previous.depositTransactionsPagination != current.depositTransactionsPagination ||
          previous.depositTransactionsTypeFilter != current.depositTransactionsTypeFilter ||
          previous.errorMessage != current.errorMessage,
      builder: (context, state) {
        final pagination = state.depositTransactionsPagination;
        final isInitialLoading = pagination.isLoading;
        final isLoadMoreLoading = pagination.status == BlocStatus.loading && pagination.list.isNotEmpty;

        if (isInitialLoading) {
          return _HistoryCard(
            title: 'سجل التحويلات المالية',
            listBody: Column(children: const [_HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem()]),
            footer: const SizedBox.shrink(),
          );
        }

        if (pagination.isFailed) {
          return _ErrorBanner(
            message: pagination.errorMessage.isNotEmpty ? pagination.errorMessage : (state.errorMessage ?? 'تعذر تحميل سجل التحويلات'),
            onRetry: () {
              context.read<ProfileBloc>().add(
                FetchDepositTransactionsEvent(
                  params: FetchDepositTransactionsParams(page: 1, perPage: WalletScreen.transfersPerPage, type: state.depositTransactionsTypeFilter),
                  isReload: true,
                  typeFilter: state.depositTransactionsTypeFilter,
                ),
              );
            },
          );
        }

        return _HistoryCard(
          title: 'سجل التحويلات المالية',
          listBody: Column(
            children: [
              _TransferFilters(selectedType: state.depositTransactionsTypeFilter),
              12.verticalSpace,
              if (pagination.isEmpty)
                const Padding(padding: EdgeInsetsDirectional.symmetric(vertical: 24), child: Text('السجل فارغ'))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pagination.list.length,
                  separatorBuilder: (context, _) => 10.verticalSpace,
                  itemBuilder: (context, index) {
                    return _TransferHistoryTile(item: pagination.list[index]);
                  },
                ),
            ],
          ),
          footer: !pagination.isEndPage
              ? Padding(
                  padding: EdgeInsetsDirectional.only(top: 12.h),
                  child: SizedBox(
                    width: context.width,
                    child: OutlinedButton(
                      onPressed: isLoadMoreLoading
                          ? null
                          : () {
                              context.read<ProfileBloc>().add(
                                FetchDepositTransactionsEvent(
                                  params: FetchDepositTransactionsParams(page: pagination.pageNumber, perPage: WalletScreen.transfersPerPage, type: state.depositTransactionsTypeFilter),
                                  loadMore: true,
                                  isReload: false,
                                  typeFilter: state.depositTransactionsTypeFilter,
                                ),
                              );
                            },
                      child: isLoadMoreLoading
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 2.5)),
                            )
                          : AppText.bodySmall('تحميل المزيد', color: const Color(0xff1E3A8A), fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _TransferFilters extends StatelessWidget {
  const _TransferFilters({required this.selectedType});

  final String? selectedType;

  @override
  Widget build(BuildContext context) {
    final options = <_TransferFilterOption>[
      const _TransferFilterOption(label: 'الكل', type: null),
      const _TransferFilterOption(label: 'إيداع', type: 'deposit'),
      const _TransferFilterOption(label: 'سحب', type: 'withdrawal'),
    ];

    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          if (index > 0) 8.horizontalSpace,
          Expanded(
            child: _TransferFilterChip(option: options[index], selectedType: selectedType),
          ),
        ],
      ],
    );
  }
}

class _TransferFilterChip extends StatelessWidget {
  const _TransferFilterChip({required this.option, required this.selectedType});

  final _TransferFilterOption option;
  final String? selectedType;

  @override
  Widget build(BuildContext context) {
    final selected = selectedType == option.type;
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () {
        context.read<ProfileBloc>().add(
          FetchDepositTransactionsEvent(
            params: FetchDepositTransactionsParams(page: 1, perPage: WalletScreen.transfersPerPage, type: option.type),
            isReload: true,
            typeFilter: option.type,
            clearTypeFilter: option.type == null,
          ),
        );
      },
      child: Container(
        height: 38.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff1E3A8A) : const Color(0xffF3F4F6),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: selected ? const Color(0xff1E3A8A) : const Color(0xffE5E7EB)),
        ),
        child: AppText.labelLarge(option.label, color: selected ? Colors.white : const Color(0xff374151), fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TransferFilterOption {
  final String label;
  final String? type;

  const _TransferFilterOption({required this.label, required this.type});
}

class _TransferHistoryTile extends StatelessWidget {
  const _TransferHistoryTile({required this.item});

  final FetchDepositTransactionsUsecaseModelDataItem item;

  bool get _isDeposit => (item.type ?? '').trim().toLowerCase() == 'deposit';

  @override
  Widget build(BuildContext context) {
    final accent = _isDeposit ? const Color(0xff16A34A) : const Color(0xffDC2626);
    final sign = _isDeposit ? '+' : '-';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 12.w, 12.h),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(color: accent.withAlpha(26), shape: BoxShape.circle),
                child: Icon(_isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: accent, size: 18),
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.bodyMedium(item.reference?.trim().isNotEmpty == true ? item.reference! : 'بدون مرجع', color: const Color(0xff111827), fontWeight: FontWeight.w700),
                    4.verticalSpace,
                    AppText.labelMedium(WalletScreen.formatDateTime(item.createdAt), color: const Color(0xff6B7280), fontWeight: FontWeight.w500),
                  ],
                ),
              ),
              AppText.bodyMedium('$sign${WalletScreen.formatAmount(item.amount ?? 0)} ل.س', color: accent, fontWeight: FontWeight.w700),
            ],
          ),
          10.verticalSpace,
          _OrderInfoBadge(title: 'الرصيد بعد العملية', value: '${WalletScreen.formatAmount(item.balanceAfter ?? 0)} ل.س', icon: Icons.account_balance_wallet_rounded),
          if (item.notes?.trim().isNotEmpty == true) ...[8.verticalSpace, _OrderInfoBadge(title: 'ملاحظات', value: item.notes!.trim(), icon: Icons.notes_rounded)],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffFECACA)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 10.h, 12.w, 10.h),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xffDC2626)),
          8.horizontalSpace,
          Expanded(
            child: AppText.labelMedium(message, color: const Color(0xff991B1B), fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: onRetry,
            child: AppText.labelLarge('إعادة المحاولة', color: const Color(0xffDC2626), fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.grossInvoicesAmount,
    required this.depositedToAdminAmount,
    required this.adminProfitAmount,
    required this.completedOrdersCount,
    required this.currencyLabel,
    required this.isLoading,
  });

  final String grossInvoicesAmount;
  final String depositedToAdminAmount;
  final String adminProfitAmount;
  final String completedOrdersCount;
  final String currencyLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge('ملخص المبالغ', color: const Color(0xff111827), fontWeight: FontWeight.w700),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _MetricTile(title: 'الايرادات', value: '$grossInvoicesAmount $currencyLabel', accentColor: const Color(0xff0EA5E9), isLoading: isLoading),
              ),
              10.horizontalSpace,
              Expanded(
                child: _MetricTile(title: 'تم ايداعه للادارة', value: '$depositedToAdminAmount $currencyLabel', accentColor: const Color(0xff10B981), isLoading: isLoading),
              ),
            ],
          ),
          10.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _MetricTile(title: 'نسبة الادارة من الارباح', value: '$adminProfitAmount $currencyLabel', accentColor: const Color(0xffF59E0B), isLoading: isLoading),
              ),
              10.horizontalSpace,
              Expanded(
                child: _MetricTile(title: 'اجمالي عدد الطلبات المكتملة', value: completedOrdersCount, accentColor: const Color(0xff6366F1), isLoading: isLoading),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value, required this.accentColor, required this.isLoading});

  final String title;
  final String value;
  final Color accentColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: accentColor.withAlpha(22), borderRadius: BorderRadius.circular(14.r)),
      padding: EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 12.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelLarge(title, color: const Color(0xff374151), fontWeight: FontWeight.w600, textAlign: TextAlign.start,),
          8.verticalSpace,
          if (isLoading) _LoadingLine(width: 90.w) else AppText.bodySmall(value, color: const Color(0xff111827), fontWeight: FontWeight.w700),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.title, required this.listBody, required this.footer});

  final String title;
  final Widget listBody;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(16.w, 16.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyLarge(title, color: const Color(0xff111827), fontWeight: FontWeight.w700),
          12.verticalSpace,
          listBody,
          footer,
        ],
      ),
    );
  }
}

class _OrdersHistoryLoadingCard extends StatelessWidget {
  const _OrdersHistoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return _HistoryCard(
      title: 'سجل الطلبات',
      listBody: Column(children: const [_HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem()]),
      footer: const SizedBox.shrink(),
    );
  }
}

class _HistoryLoadingItem extends StatelessWidget {
  const _HistoryLoadingItem();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xffE5E7EB),
      highlightColor: const Color(0xffF3F4F6),
      child: Container(
        width: context.width,
        height: 92.h,
        decoration: BoxDecoration(color: const Color(0xffE5E7EB), borderRadius: BorderRadius.circular(14.r)),
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  const _OrderHistoryTile({required this.order, required this.index});

  final FetchOrdersUsecaseModelDataItem order;
  final int index;

  String _resolveOrderNumber() {
    final bookingNumber = order.bookingNumber?.trim();
    if (bookingNumber != null && bookingNumber.isNotEmpty) {
      return bookingNumber;
    }
    final id = order.id;
    if (id == null) return '-';
    return '#$id';
  }

  void _openDetails(BuildContext context) {
    final bookingId = order.id;
    if (bookingId == null) return;
    context.pushRoute(
      '/orderdetails',
      arguments: OrderDetailsScreenParams(order: order, isNewOrder: false, bloc: context.read<OrdersBloc>(), index: index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = order.totalPrice ?? 0;
    final adminMargin = order.adminMargin ?? 0;
    final date = WalletScreen.formatScheduledDate(order.scheduledDate);
    final time = WalletScreen.formatScheduledTime(order.scheduledTime);

    return InkWell(
      onTap: () => _openDetails(context),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        padding: EdgeInsetsDirectional.fromSTEB(12.w, 12.h, 12.w, 12.h),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText.bodyMedium('رقم الطلب: ${_resolveOrderNumber()}', color: const Color(0xff111827), fontWeight: FontWeight.w700),
                ),
                AppText.bodyMedium('${WalletScreen.formatAmount(totalPrice)} ل.س', color: const Color(0xff1E3A8A), fontWeight: FontWeight.w700),
              ],
            ),
            10.verticalSpace,
            _OrderInfoBadge(title: 'التاريخ والوقت', value: '$date - $time', icon: Icons.calendar_today_rounded),
            8.verticalSpace,
            _OrderInfoBadge(title: 'مبلغ الإدارة', value: '${WalletScreen.formatAmount(adminMargin)} ل.س', icon: Icons.account_balance_wallet_rounded),
          ],
        ),
      ),
    );
  }
}

class _OrderInfoBadge extends StatelessWidget {
  const _OrderInfoBadge({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(10.w, 8.h, 10.w, 8.h),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelMedium(title, color: const Color(0xff6B7280), fontWeight: FontWeight.w500),
                4.verticalSpace,
                AppText.labelLarge(value, color: const Color(0xff111827), fontWeight: FontWeight.w700),
              ],
            ),
          ),
          Icon(icon, size: 16, color: const Color(0xff4B5563)),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xffE5E7EB),
      highlightColor: const Color(0xffF3F4F6),
      child: Container(
        width: width,
        height: 12.h,
        decoration: BoxDecoration(color: const Color(0xffE5E7EB), borderRadius: BorderRadius.circular(9999.r)),
      ),
    );
  }
}
