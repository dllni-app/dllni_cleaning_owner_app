import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/core/utils/cleaning_arabic_time_formatter.dart';
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
    return currency == null || currency.isEmpty || currency == 'SYP' ? 'ل.س' : currency;
  }

  static String formatAmount(num value) {
    final fixed = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    if (parts.length == 1) return whole;
    final fraction = parts[1].replaceAll(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole : '$whole.$fraction';
  }

  static String formatScheduledDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate);
    return parsed == null ? rawDate : DateFormat('yyyy-MM-dd', 'en').format(parsed);
  }

  static String formatScheduledTime(String? rawTime) => CleaningArabicTimeFormatter.formatScheduledTime(rawTime);
  static String formatDateTime(String? rawDateTime) => CleaningArabicTimeFormatter.formatDateTime(rawDateTime);
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedHistoryTab = 0;

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
            ..add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, perPage: WalletScreen.ordersPerPage, status: CleaningBookingStatus.completed), isReload: true)),
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xffF3F4F6),
        body: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsetsDirectional.fromSTEB(20.w, 18.h, 20.w, 24.h),
                  child: Column(
                    children: [_trustCard(), 16.verticalSpace, _financeSummary(), 16.verticalSpace, _depositSection(), 16.verticalSpace, _historySection()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Container(
      width: context.width,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24.r), bottomRight: Radius.circular(24.r)), border: Border(bottom: BorderSide(color: context.primaryContainer, width: 2))),
      padding: EdgeInsetsDirectional.symmetric(horizontal: 22.w, vertical: 16.h),
      child: Row(children: [InkWell(onTap: () => context.pop(), child: Icon(Icons.arrow_back_ios_new, color: context.primaryContainer)), 10.horizontalSpace, _text('احصائياتي', size: 26, color: context.primaryContainer, weight: FontWeight.w700)]),
    );
  }

  Widget _trustCard() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (p, c) => p.workerProfileUsecaseStatus != c.workerProfileUsecaseStatus || p.workerProfileUsecase != c.workerProfileUsecase,
      builder: (context, state) {
        final isLoading = state.workerProfileUsecaseStatus == null || state.workerProfileUsecaseStatus == BlocStatus.loading || state.workerProfileUsecaseStatus == BlocStatus.init;
        final trustScore = state.workerProfileUsecase?.data?.trustScore;
        return _card(
          child: Row(children: [
            _circleIcon(Icons.stars_rounded, const Color(0xff7E22CE)),
            12.horizontalSpace,
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text('نقاط الثقة', weight: FontWeight.w700), 4.verticalSpace, isLoading ? _loadingLine(96.w) : _text('%${trustScore ?? 0} نقاط الثقة', color: const Color(0xff7E22CE), weight: FontWeight.w600, size: 14)])),
          ]),
        );
      },
    );
  }

  Widget _financeSummary() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final isLoading = state.homePageUsecaseStatus == null || state.homePageUsecaseStatus == BlocStatus.loading || state.homePageUsecaseStatus == BlocStatus.init;
        final model = state.homePageUsecase;
        final amountSummary = model?.amountSummary;
        final currency = WalletScreen.resolveCurrencyLabel(amountSummary?.currency);
        return Column(children: [
          if (state.homePageUsecaseStatus == BlocStatus.failed) ...[_errorBanner(state.errorMessage ?? 'حدث خطأ ما', () => context.read<HomeBloc>().add(FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()))), 16.verticalSpace],
          _card(
            shadow: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _text('ملخص المبالغ', weight: FontWeight.w700),
              12.verticalSpace,
              Row(children: [Expanded(child: _metric('الايرادات', '${WalletScreen.formatAmount(amountSummary?.grossInvoicesAmount ?? 0)} $currency', const Color(0xff0EA5E9), isLoading)), 10.horizontalSpace, Expanded(child: _metric('تم ايداعه للادارة', '${WalletScreen.formatAmount(amountSummary?.workerAmount ?? 0)} $currency', const Color(0xff10B981), isLoading))]),
              10.verticalSpace,
              Row(children: [Expanded(child: _metric('نسبة الادارة من الارباح', '${WalletScreen.formatAmount(amountSummary?.adminAmount ?? 0)} $currency', const Color(0xffF59E0B), isLoading)), 10.horizontalSpace, Expanded(child: _metric('اجمالي عدد الطلبات المكتملة', WalletScreen.formatAmount(model?.completedCount ?? 0), const Color(0xff6366F1), isLoading))]),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _depositSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (p, c) => p.depositAccountStatus != c.depositAccountStatus || p.depositAccount != c.depositAccount,
      builder: (context, state) {
        final isLoading = state.depositAccountStatus == null || state.depositAccountStatus == BlocStatus.loading || state.depositAccountStatus == BlocStatus.init;
        final data = state.depositAccount;
        const currency = 'ل.س';
        return Column(children: [
          if (state.depositAccountStatus == BlocStatus.failed) ...[_errorBanner(state.errorMessage ?? 'تعذر تحميل بيانات التأمين', () => context.read<ProfileBloc>().add(FetchDepositAccountEvent())), 12.verticalSpace],
          _debtCard(WalletScreen.formatAmount(data?.debtAmount ?? 0), currency, isLoading),
          12.verticalSpace,
          _card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: _text('حالة مبلغ التأمين', weight: FontWeight.w700)), isLoading ? _loadingLine(74.w) : _statusBadge(data?.status ?? '')]),
              12.verticalSpace,
              Row(children: [Expanded(child: _metric('الرصيد الحالي', '${WalletScreen.formatAmount(data?.currentBalance ?? 0)} $currency', const Color(0xff0EA5E9), isLoading)), 10.horizontalSpace, Expanded(child: _metric('الحد الأدنى المطلوب', '${WalletScreen.formatAmount(data?.minimumRequired ?? 0)} $currency', const Color(0xffF59E0B), isLoading))]),
              10.verticalSpace,
              Row(children: [Expanded(child: _metric('إجمالي الإيداع', '${WalletScreen.formatAmount(data?.depositedTotal ?? 0)} $currency', const Color(0xff10B981), isLoading)), 10.horizontalSpace, Expanded(child: _metric('إجمالي السحب', '${WalletScreen.formatAmount(data?.withdrawnTotal ?? 0)} $currency', const Color(0xffEF4444), isLoading))]),
              if ((data?.exceedanceAmount ?? 0) > 0) ...[12.verticalSpace, Container(width: context.width, padding: EdgeInsetsDirectional.all(10.w), decoration: BoxDecoration(color: const Color(0xffFEF2F2), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: const Color(0xffFECACA))), child: _text('مقدار التجاوز: ${WalletScreen.formatAmount(data?.exceedanceAmount ?? 0)} $currency', color: const Color(0xffB91C1C), weight: FontWeight.w700, size: 14))],
            ]),
          ),
        ]);
      },
    );
  }

  Widget _debtCard(String amount, String currency, bool isLoading) {
    return _card(
      borderColor: const Color(0xffFECACA),
      child: Row(children: [
        _circleIcon(Icons.account_balance_wallet_outlined, const Color(0xffDC2626)),
        12.horizontalSpace,
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text('المديونية', weight: FontWeight.w700), 4.verticalSpace, isLoading ? _loadingLine(110.w) : _text('$amount $currency', color: const Color(0xffB91C1C), weight: FontWeight.w800, size: 14)])),
      ]),
    );
  }

  Widget _historySection() {
    return Column(children: [
      _card(
        padding: EdgeInsetsDirectional.all(10.w),
        child: Row(children: [Expanded(child: _historyChip('سجل الطلبات', _selectedHistoryTab == 0, () => setState(() => _selectedHistoryTab = 0))), 8.horizontalSpace, Expanded(child: _historyChip('سجل الحركة المالية', _selectedHistoryTab == 1, () => setState(() => _selectedHistoryTab = 1)))]),
      ),
      12.verticalSpace,
      _selectedHistoryTab == 0 ? _ordersHistory() : _financialMovementHistory(),
    ]);
  }

  Widget _ordersHistory() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      buildWhen: (p, c) => p.ordersUsecase != c.ordersUsecase || p.errorMessage != c.errorMessage,
      builder: (context, state) {
        final pagination = state.ordersUsecase;
        if (pagination == null || pagination.isLoading) return _historyCard('سجل الطلبات', Column(children: const [_HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem()]));
        if (pagination.isFailed) return _errorBanner(pagination.errorMessage.isNotEmpty ? pagination.errorMessage : (state.errorMessage ?? 'تعذر تحميل سجل الطلبات'), () => context.read<OrdersBloc>().add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: 1, perPage: WalletScreen.ordersPerPage, status: CleaningBookingStatus.completed), isReload: true)));
        final body = pagination.isEmpty ? const Padding(padding: EdgeInsetsDirectional.symmetric(vertical: 24), child: Center(child: Text('السجل فارغ'))) : ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: pagination.list.length, separatorBuilder: (_, __) => 10.verticalSpace, itemBuilder: (context, index) => _orderTile(pagination.list[index], index));
        return _historyCard('سجل الطلبات', body, footer: _loadMoreOrders(pagination));
      },
    );
  }

  Widget _financialMovementHistory() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (p, c) => p.depositTransactionsPagination != c.depositTransactionsPagination || p.depositTransactionsTypeFilter != c.depositTransactionsTypeFilter || p.errorMessage != c.errorMessage,
      builder: (context, state) {
        final pagination = state.depositTransactionsPagination;
        if (pagination.isLoading) return _historyCard('سجل الحركة المالية', Column(children: const [_HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem(), SizedBox(height: 10), _HistoryLoadingItem()]));
        if (pagination.isFailed) return _errorBanner(pagination.errorMessage.isNotEmpty ? pagination.errorMessage : (state.errorMessage ?? 'تعذر تحميل سجل الحركة المالية'), () => context.read<ProfileBloc>().add(FetchDepositTransactionsEvent(params: FetchDepositTransactionsParams(page: 1, perPage: WalletScreen.transfersPerPage, type: state.depositTransactionsTypeFilter), isReload: true, typeFilter: state.depositTransactionsTypeFilter)));
        final list = pagination.isEmpty ? const Padding(padding: EdgeInsetsDirectional.symmetric(vertical: 24), child: Center(child: Text('السجل فارغ'))) : ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: pagination.list.length, separatorBuilder: (_, __) => 10.verticalSpace, itemBuilder: (_, index) => _transactionTile(pagination.list[index]));
        return _historyCard('سجل الحركة المالية', Column(children: [_transferFilters(state.depositTransactionsTypeFilter), 12.verticalSpace, list]), footer: _loadMoreTransactions(pagination, state.depositTransactionsTypeFilter));
      },
    );
  }

  Widget _transferFilters(String? selectedType) {
    const options = [
      _TransferFilterOption('الكل', null),
      _TransferFilterOption('إيداع', 'deposit'),
      _TransferFilterOption('سحب', 'withdrawal'),
      _TransferFilterOption('مديونية', 'admin_fee'),
      _TransferFilterOption('تسوية', 'settlement'),
      _TransferFilterOption('استرداد', 'refund'),
      _TransferFilterOption('تعديل', 'adjustment'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [for (var i = 0; i < options.length; i++) ...[if (i > 0) 8.horizontalSpace, SizedBox(width: 96.w, child: _filterChip(options[i], selectedType))]]),
    );
  }

  Widget _filterChip(_TransferFilterOption option, String? selectedType) {
    final selected = selectedType == option.type;
    return InkWell(
      borderRadius: BorderRadius.circular(10.r),
      onTap: () => context.read<ProfileBloc>().add(FetchDepositTransactionsEvent(params: FetchDepositTransactionsParams(page: 1, perPage: WalletScreen.transfersPerPage, type: option.type), isReload: true, typeFilter: option.type, clearTypeFilter: option.type == null)),
      child: Container(height: 38.h, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? const Color(0xff1E3A8A) : const Color(0xffF3F4F6), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: selected ? const Color(0xff1E3A8A) : const Color(0xffE5E7EB))), child: _text(option.label, color: selected ? Colors.white : const Color(0xff374151), weight: FontWeight.w700, size: 14)),
    );
  }

  Widget _loadMoreOrders(dynamic pagination) {
    final isLoading = pagination.status == BlocStatus.loading && pagination.list.isNotEmpty;
    if (pagination.isEndPage) return const SizedBox.shrink();
    return _loadMoreButton(isLoading, () => context.read<OrdersBloc>().add(FetchOrdersUsecaseEvent(params: FetchOrdersUsecaseParams(page: pagination.pageNumber, perPage: WalletScreen.ordersPerPage, status: CleaningBookingStatus.completed), isReload: false)));
  }

  Widget _loadMoreTransactions(dynamic pagination, String? selectedType) {
    final isLoading = pagination.status == BlocStatus.loading && pagination.list.isNotEmpty;
    if (pagination.isEndPage) return const SizedBox.shrink();
    return _loadMoreButton(isLoading, () => context.read<ProfileBloc>().add(FetchDepositTransactionsEvent(params: FetchDepositTransactionsParams(page: pagination.pageNumber, perPage: WalletScreen.transfersPerPage, type: selectedType), loadMore: true, isReload: false, typeFilter: selectedType)));
  }

  Widget _loadMoreButton(bool isLoading, VoidCallback onPressed) {
    return Padding(padding: EdgeInsetsDirectional.only(top: 12.h), child: SizedBox(width: context.width, child: OutlinedButton(onPressed: isLoading ? null : onPressed, child: isLoading ? SizedBox(width: 18.w, height: 18.w, child: const FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 2.5))) : _text('تحميل المزيد', color: const Color(0xff1E3A8A), weight: FontWeight.w700, size: 13))));
  }

  Widget _orderTile(FetchOrdersUsecaseModelDataItem order, int index) {
    final bookingNumber = order.bookingNumber?.trim().isNotEmpty == true ? order.bookingNumber!.trim() : (order.id == null ? '-' : '#${order.id}');
    return InkWell(
      onTap: () {
        if (order.id == null) return;
        context.pushRoute('/orderdetails', arguments: OrderDetailsScreenParams(order: order, isNewOrder: false, bloc: context.read<OrdersBloc>(), index: index));
      },
      borderRadius: BorderRadius.circular(14.r),
      child: _listTile(children: [Row(children: [Expanded(child: _text('رقم الطلب: $bookingNumber', weight: FontWeight.w700, size: 14)), _text('${WalletScreen.formatAmount(order.totalPrice ?? 0)} ل.س', color: const Color(0xff1E3A8A), weight: FontWeight.w700, size: 14)]), 10.verticalSpace, _infoBadge('التاريخ والوقت', '${WalletScreen.formatScheduledDate(order.scheduledDate)} - ${WalletScreen.formatScheduledTime(order.scheduledTime)}', Icons.calendar_today_rounded), 8.verticalSpace, _infoBadge('مبلغ الإدارة', '${WalletScreen.formatAmount(order.adminMargin ?? 0)} ل.س', Icons.account_balance_wallet_rounded)]),
    );
  }

  Widget _transactionTile(FetchDepositTransactionsUsecaseModelDataItem item) {
    final isCredit = _isCreditTransaction(item);
    final accent = isCredit ? const Color(0xff16A34A) : const Color(0xffDC2626);
    final sign = isCredit ? '+' : '-';
    final amount = (item.amount ?? 0) < 0 ? -(item.amount ?? 0) : (item.amount ?? 0);
    final reference = item.reference?.trim();
    final notes = item.notes?.trim();
    return _listTile(children: [
      Row(children: [_circleIcon(_transactionIcon(item.type, isCredit), accent, size: 32.w, iconSize: 18), 10.horizontalSpace, Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text(_transactionTitle(item), weight: FontWeight.w700, size: 14), 4.verticalSpace, _text(WalletScreen.formatDateTime(item.createdAt), color: const Color(0xff6B7280), weight: FontWeight.w500, size: 12)])), _text('$sign${WalletScreen.formatAmount(amount)} ل.س', color: accent, weight: FontWeight.w700, size: 14)]),
      10.verticalSpace,
      _infoBadge('الرصيد بعد العملية', '${WalletScreen.formatAmount(item.balanceAfter ?? 0)} ل.س', Icons.account_balance_wallet_rounded),
      if (reference != null && reference.isNotEmpty) ...[8.verticalSpace, _infoBadge('المرجع', reference, Icons.tag_rounded)],
      if (notes != null && notes.isNotEmpty) ...[8.verticalSpace, _infoBadge('ملاحظات', notes, Icons.notes_rounded)],
    ]);
  }

  bool _isCreditTransaction(FetchDepositTransactionsUsecaseModelDataItem item) {
    if (item.balanceBefore != null && item.balanceAfter != null && item.balanceBefore != item.balanceAfter) return item.balanceAfter! > item.balanceBefore!;
    final type = (item.type ?? '').trim().toLowerCase();
    if (type == 'deposit' || type == 'settlement') return true;
    if (type == 'withdrawal' || type == 'admin_fee' || type == 'refund') return false;
    return (item.amount ?? 0) >= 0;
  }

  String _transactionTitle(FetchDepositTransactionsUsecaseModelDataItem item) {
    final type = (item.type ?? '').trim().toLowerCase();
    if (type == 'admin_fee' && item.cleaningBookingId != null) return 'مديونية الطلب #${item.cleaningBookingId}';
    switch (type) { case 'deposit': return 'إيداع'; case 'withdrawal': return 'سحب'; case 'admin_fee': return 'مديونية'; case 'settlement': return 'تسوية مديونية'; case 'refund': return 'استرداد'; case 'adjustment': return 'تعديل رصيد'; default: return 'حركة مالية'; }
  }

  IconData _transactionIcon(String? rawType, bool isCredit) {
    switch ((rawType ?? '').trim().toLowerCase()) { case 'admin_fee': return Icons.trending_down_rounded; case 'settlement': return Icons.payments_rounded; case 'adjustment': return Icons.tune_rounded; case 'withdrawal': case 'refund': return Icons.arrow_upward_rounded; default: return isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded; }
  }

  Widget _historyChip(String label, bool selected, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12.r), child: Container(height: 42.h, alignment: Alignment.center, decoration: BoxDecoration(color: selected ? const Color(0xff1E3A8A) : const Color(0xffF3F4F6), borderRadius: BorderRadius.circular(12.r), border: Border.all(color: selected ? const Color(0xff1E3A8A) : const Color(0xffE5E7EB))), child: _text(label, color: selected ? Colors.white : const Color(0xff374151), weight: FontWeight.w700, size: 14)));
  }

  Widget _metric(String title, String value, Color accentColor, bool isLoading) => Container(decoration: BoxDecoration(color: accentColor.withAlpha(22), borderRadius: BorderRadius.circular(14.r)), padding: EdgeInsetsDirectional.all(12.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text(title, color: const Color(0xff374151), weight: FontWeight.w600, size: 13), 8.verticalSpace, isLoading ? _loadingLine(90.w) : _text(value, weight: FontWeight.w700, size: 13)]));

  Widget _historyCard(String title, Widget body, {Widget footer = const SizedBox.shrink()}) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text(title, weight: FontWeight.w700), 12.verticalSpace, body, footer]));

  Widget _listTile({required List<Widget> children}) => Container(decoration: BoxDecoration(color: const Color(0xffF9FAFB), borderRadius: BorderRadius.circular(14.r), border: Border.all(color: const Color(0xffE5E7EB))), padding: EdgeInsetsDirectional.all(12.w), child: Column(children: children));

  Widget _infoBadge(String title, String value, IconData icon) => Container(padding: EdgeInsetsDirectional.fromSTEB(10.w, 8.h, 10.w, 8.h), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_text(title, color: const Color(0xff6B7280), weight: FontWeight.w500, size: 12), 4.verticalSpace, _text(value, weight: FontWeight.w700, size: 13)])), Icon(icon, size: 16, color: const Color(0xff4B5563))]));

  Widget _card({required Widget child, EdgeInsetsGeometry? padding, Color borderColor = const Color(0xffE5E7EB), bool shadow = false}) => Container(width: context.width, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), border: Border.all(color: borderColor), boxShadow: shadow ? [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 14, offset: const Offset(0, 4))] : null), padding: padding ?? EdgeInsetsDirectional.all(16.w), child: child);

  Widget _circleIcon(IconData icon, Color color, {double? size, double iconSize = 22}) => Container(width: size ?? 42.w, height: size ?? 42.w, decoration: BoxDecoration(color: color.withAlpha(28), shape: BoxShape.circle), child: Icon(icon, color: color, size: iconSize));

  Widget _statusBadge(String status) {
    final color = status == 'active' ? const Color(0xff16A34A) : (status == 'suspended' ? const Color(0xff7C3AED) : const Color(0xffDC2626));
    final label = status == 'active' ? 'نشط' : (status == 'suspended' ? 'معلق' : (status == 'inactive' ? 'غير فعال' : 'رصيد غير كاف'));
    return Container(padding: EdgeInsetsDirectional.symmetric(horizontal: 10.w, vertical: 5.h), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(999.r)), child: _text(label, color: color, weight: FontWeight.w700, size: 12));
  }

  Widget _errorBanner(String message, VoidCallback onRetry) => Container(width: context.width, decoration: BoxDecoration(color: const Color(0xffFEF2F2), borderRadius: BorderRadius.circular(16.r), border: Border.all(color: const Color(0xffFECACA))), padding: EdgeInsetsDirectional.fromSTEB(12.w, 10.h, 12.w, 10.h), child: Row(children: [const Icon(Icons.error_outline, color: Color(0xffDC2626)), 8.horizontalSpace, Expanded(child: _text(message, color: const Color(0xff991B1B), weight: FontWeight.w600, size: 12)), TextButton(onPressed: onRetry, child: _text('إعادة المحاولة', color: const Color(0xffDC2626), weight: FontWeight.w700, size: 13))]));

  Widget _loadingLine(double width) => Shimmer.fromColors(baseColor: const Color(0xffE5E7EB), highlightColor: const Color(0xffF3F4F6), child: Container(width: width, height: 12.h, decoration: BoxDecoration(color: const Color(0xffE5E7EB), borderRadius: BorderRadius.circular(9999.r))));

  Widget _text(String text, {double size = 16, Color color = const Color(0xff111827), FontWeight weight = FontWeight.w400}) => Text(text, textAlign: TextAlign.start, style: TextStyle(fontSize: size.sp, color: color, fontWeight: weight));
}

class _TransferFilterOption {
  final String label;
  final String? type;
  const _TransferFilterOption(this.label, this.type);
}

class _HistoryLoadingItem extends StatelessWidget {
  const _HistoryLoadingItem();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(baseColor: const Color(0xffE5E7EB), highlightColor: const Color(0xffF3F4F6), child: Container(width: context.width, height: 92.h, decoration: BoxDecoration(color: const Color(0xffE5E7EB), borderRadius: BorderRadius.circular(14.r))));
  }
}
