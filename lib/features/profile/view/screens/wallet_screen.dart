import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/home/domain/usecases/fetch_home_page_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/home/view/manager/bloc/home_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();

  static String resolveCurrencyLabel(String? rawCurrency) {
    final currency = rawCurrency?.trim().toUpperCase();
    return currency == null || currency.isEmpty || currency == 'SYP'
        ? 'ل.س'
        : currency;
  }

  static String formatAmount(num value) {
    final fixed = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    if (parts.length == 1) return whole;
    final fraction = parts[1].replaceAll(RegExp(r'0+$'), '');
    return fraction.isEmpty ? whole : '$whole.$fraction';
  }
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProfileBloc>().add(FetchDepositAccountEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      lazy: false,
      create: (_) => getIt<HomeBloc>()
        ..add(
          FetchHomePageUsecaseEvent(
            params: FetchHomePageUsecaseParams(),
          ),
        ),
      child: Builder(
        builder: (providerContext) => Scaffold(
          backgroundColor: const Color(0xffF3F4F6),
          body: SafeArea(
            child: Column(
              children: [
                _appBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _refresh(providerContext),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsetsDirectional.fromSTEB(
                        20.w,
                        18.h,
                        20.w,
                        24.h,
                      ),
                      children: [
                        _financeSummary(),
                        16.verticalSpace,
                        _depositSection(),
                      ],
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

  Future<void> _refresh(BuildContext providerContext) async {
    providerContext.read<HomeBloc>().add(
      FetchHomePageUsecaseEvent(params: FetchHomePageUsecaseParams()),
    );
    context.read<ProfileBloc>().add(FetchDepositAccountEvent());
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Widget _appBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
        border: Border(
          bottom: BorderSide(color: context.primaryContainer, width: 2),
        ),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: 22.w,
        vertical: 16.h,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: context.primaryContainer,
            ),
          ),
          10.horizontalSpace,
          _text(
            'احصائياتي',
            size: 26,
            color: context.primaryContainer,
            weight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _financeSummary() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final isLoading =
            state.homePageUsecaseStatus == null ||
            state.homePageUsecaseStatus == BlocStatus.loading ||
            state.homePageUsecaseStatus == BlocStatus.init;
        final model = state.homePageUsecase;
        final amountSummary = model?.amountSummary;
        final currency = WalletScreen.resolveCurrencyLabel(
          amountSummary?.currency,
        );

        return Column(
          children: [
            if (state.homePageUsecaseStatus == BlocStatus.failed) ...[
              _errorBanner(
                ErrorMessageFormatter.format(
                  state.errorMessage,
                  fallback: 'تعذر تحميل ملخص المبالغ',
                ),
                () => context.read<HomeBloc>().add(
                  FetchHomePageUsecaseEvent(
                    params: FetchHomePageUsecaseParams(),
                  ),
                ),
              ),
              12.verticalSpace,
            ],
            _card(
              shadow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text('ملخص المبالغ', weight: FontWeight.w700, size: 20),
                  14.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'الإيرادات',
                          '${WalletScreen.formatAmount(amountSummary?.grossInvoicesAmount ?? 0)} $currency',
                          const Color(0xff0EA5E9),
                          isLoading,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _metric(
                          'تم إيداعه للإدارة',
                          '${WalletScreen.formatAmount(amountSummary?.workerAmount ?? 0)} $currency',
                          const Color(0xff10B981),
                          isLoading,
                        ),
                      ),
                    ],
                  ),
                  10.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'نسبة الإدارة من الأرباح',
                          '${WalletScreen.formatAmount(amountSummary?.adminAmount ?? 0)} $currency',
                          const Color(0xffF59E0B),
                          isLoading,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _metric(
                          'إجمالي عدد الطلبات المكتملة',
                          WalletScreen.formatAmount(model?.completedCount ?? 0),
                          const Color(0xff6366F1),
                          isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _depositSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          previous.depositAccountStatus != current.depositAccountStatus ||
          previous.depositAccount != current.depositAccount,
      builder: (context, state) {
        final isLoading =
            state.depositAccountStatus == null ||
            state.depositAccountStatus == BlocStatus.loading ||
            state.depositAccountStatus == BlocStatus.init;
        final data = state.depositAccount;
        const currency = 'ل.س';

        return Column(
          children: [
            if (state.depositAccountStatus == BlocStatus.failed) ...[
              _errorBanner(
                ErrorMessageFormatter.format(
                  state.errorMessage,
                  fallback: 'تعذر تحميل بيانات مبلغ التأمين',
                ),
                () => context.read<ProfileBloc>().add(
                  FetchDepositAccountEvent(),
                ),
              ),
              12.verticalSpace,
            ],
            _debtCard(
              WalletScreen.formatAmount(data?.manualDebtAmount ?? 0),
              currency,
              isLoading,
            ),
            12.verticalSpace,
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _text(
                          'حالة مبلغ التأمين',
                          weight: FontWeight.w700,
                          size: 20,
                        ),
                      ),
                      isLoading
                          ? _loadingLine(74.w)
                          : _statusBadge(data?.status ?? ''),
                    ],
                  ),
                  14.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'الرصيد الحالي',
                          '${WalletScreen.formatAmount(data?.currentBalance ?? 0)} $currency',
                          const Color(0xff0EA5E9),
                          isLoading,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _metric(
                          'الحد الأدنى المطلوب',
                          '${WalletScreen.formatAmount(data?.minimumRequired ?? 0)} $currency',
                          const Color(0xffF59E0B),
                          isLoading,
                        ),
                      ),
                    ],
                  ),
                  10.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _metric(
                          'إجمالي الإيداع',
                          '${WalletScreen.formatAmount(data?.depositedTotal ?? 0)} $currency',
                          const Color(0xff10B981),
                          isLoading,
                        ),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: _metric(
                          'إجمالي السحب',
                          '${WalletScreen.formatAmount(data?.withdrawnTotal ?? 0)} $currency',
                          const Color(0xffEF4444),
                          isLoading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _debtCard(String amount, String currency, bool isLoading) {
    return _card(
      borderColor: const Color(0xffFECACA),
      child: Row(
        children: [
          _circleIcon(
            Icons.account_balance_wallet_outlined,
            const Color(0xffDC2626),
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text('قيمة الدين', weight: FontWeight.w700, size: 18),
                4.verticalSpace,
                isLoading
                    ? _loadingLine(110.w)
                    : _text(
                        '$amount $currency',
                        color: const Color(0xffB91C1C),
                        weight: FontWeight.w800,
                        size: 16,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String title,
    String value,
    Color color,
    bool isLoading,
  ) {
    return Container(
      constraints: BoxConstraints(minHeight: 104.h),
      padding: EdgeInsetsDirectional.all(14.w),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _text(title, size: 15, color: const Color(0xff374151)),
          8.verticalSpace,
          isLoading
              ? _loadingLine(84.w)
              : _text(value, size: 16, weight: FontWeight.w700),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.trim().toLowerCase();
    final isActive = normalized == 'active';
    final label = switch (normalized) {
      'active' => 'نشط',
      'restricted' || 'insufficient_balance' => 'غير نشط',
      'suspended' => 'موقوف',
      'inactive' => 'غير نشط',
      _ => 'غير محدد',
    };
    final color = isActive ? const Color(0xff059669) : const Color(0xffDC2626);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: _text(label, color: color, size: 14, weight: FontWeight.w700),
    );
  }

  Widget _card({
    required Widget child,
    Color? borderColor,
    bool shadow = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor ?? const Color(0xffE5E7EB)),
        boxShadow: shadow
            ? const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24.sp),
    );
  }

  Widget _errorBanner(String message, VoidCallback retry) {
    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xffFEF2F2),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xffFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xffB91C1C)),
          10.horizontalSpace,
          Expanded(
            child: _text(message, color: const Color(0xffB91C1C), size: 14),
          ),
          TextButton(onPressed: retry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  Widget _loadingLine(double width) {
    return Container(
      width: width,
      height: 14.h,
      decoration: BoxDecoration(
        color: const Color(0xffE5E7EB),
        borderRadius: BorderRadius.circular(999.r),
      ),
    );
  }

  Widget _text(
    String value, {
    double size = 16,
    Color color = const Color(0xff111827),
    FontWeight weight = FontWeight.w400,
  }) {
    return Text(
      value,
      textAlign: TextAlign.start,
      style: TextStyle(
        fontSize: size.sp,
        color: color,
        fontWeight: weight,
        height: 1.35,
      ),
    );
  }
}
