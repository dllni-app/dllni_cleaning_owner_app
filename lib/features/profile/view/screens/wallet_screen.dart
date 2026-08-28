import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_deposit_account_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_worker_profile_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../../../../core/theme/app_layout.dart';
import '../../../../core/widgets/app_page_header.dart';

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
      final profileBloc = context.read<ProfileBloc>();
      profileBloc.add(FetchDepositAccountEvent());
      profileBloc.add(
        FetchWorkerProfileUsecaseEvent(
          params: FetchWorkerProfileUsecaseParams(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpace.pagePadding(context).add(
                    const EdgeInsetsDirectional.symmetric(
                      vertical: AppSpace.md,
                    ),
                  ),
                  children: [
                    _trustScoreSection(),
                    16.verticalSpace,
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
    );
  }

  Future<void> _refresh() async {
    final profileBloc = context.read<ProfileBloc>();
    profileBloc.add(FetchDepositAccountEvent());
    profileBloc.add(
      FetchWorkerProfileUsecaseEvent(params: FetchWorkerProfileUsecaseParams()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Widget _appBar() {
    return const AppPageHeader(
      title: 'المحفظة والإحصائيات',
      subtitle: 'ملخص أرباحك ورصيد التأمين وسجل الحركة المالية',
    );
  }

  Widget _trustScoreSection() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          previous.workerProfileUsecaseStatus !=
              current.workerProfileUsecaseStatus ||
          previous.workerProfileUsecase != current.workerProfileUsecase,
      builder: (context, state) {
        final status = state.workerProfileUsecaseStatus;
        final isLoading =
            status == null ||
            status == BlocStatus.loading ||
            status == BlocStatus.init;
        final trustScore = state.workerProfileUsecase?.data?.trustScore;
        final normalizedScore = (trustScore ?? 0).clamp(0, 100).toInt();

        return Column(
          children: [
            if (status == BlocStatus.failed) ...[
              _errorBanner(
                ErrorMessageFormatter.format(
                  state.errorMessage,
                  fallback: 'تعذر تحميل نسبة الثقة',
                ),
                () => context.read<ProfileBloc>().add(
                  FetchWorkerProfileUsecaseEvent(
                    params: FetchWorkerProfileUsecaseParams(),
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
                  Row(
                    children: [
                      _circleIcon(
                        Icons.verified_user_outlined,
                        const Color(0xff7C3AED),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _text(
                              'نسبة الثقة',
                              weight: FontWeight.w700,
                              size: 20,
                            ),
                            4.verticalSpace,
                            _text(
                              'تعكس مستوى موثوقيتك في تنفيذ الطلبات',
                              color: const Color(0xff6B7280),
                              size: 13,
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        _loadingLine(64.w)
                      else
                        _text(
                          trustScore == null ? '—' : '$trustScore%',
                          color: const Color(0xff7C3AED),
                          weight: FontWeight.w800,
                          size: 24,
                        ),
                    ],
                  ),
                  16.verticalSpace,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999.r),
                    child: LinearProgressIndicator(
                      minHeight: 10.h,
                      value: isLoading || trustScore == null
                          ? null
                          : normalizedScore / 100,
                      backgroundColor: const Color(0xffEDE9FE),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xff7C3AED),
                      ),
                    ),
                  ),
                  if (!isLoading && trustScore == null) ...[
                    10.verticalSpace,
                    _text(
                      'نسبة الثقة غير متاحة حالياً.',
                      color: const Color(0xff6B7280),
                      size: 13,
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

  Widget _financeSummary() {
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
        final parsedWorkerAmount = data?.totalRevenue;
        final adminAmount =
            data?.totalCommission ?? data?.adminCommissionBalance ?? 0;
        final grossAmount =
            data?.grossInvoicesAmount ??
            (parsedWorkerAmount ?? 0) + adminAmount;
        final workerAmount = parsedWorkerAmount ?? grossAmount - adminAmount;

        return _card(
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
                      'الإجمالي',
                      '${WalletScreen.formatAmount(grossAmount)} $currency',
                      const Color(0xff0EA5E9),
                      isLoading,
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: _metric(
                      'صافي الربح',
                      '${WalletScreen.formatAmount(workerAmount)} $currency',
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
                      'هامش الإدارة',
                      '${WalletScreen.formatAmount(adminAmount)} $currency',
                      const Color(0xffF59E0B),
                      isLoading,
                    ),
                  ),
                  10.horizontalSpace,
                  Expanded(
                    child: _metric(
                      'إجمالي عدد الطلبات المكتملة',
                      WalletScreen.formatAmount(data?.completedJobs ?? 0),
                      const Color(0xff6366F1),
                      isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
        final accountStatus = data?.isFinancialAccountActive == false
            ? 'inactive'
            : data?.status ?? '';
        final hasDepositBalance = (data?.currentBalance ?? 0) > 0;
        final warningText = isLoading || data == null
            ? null
            : _financialWarningText(data);
        final warningIsDanger =
            data?.isEligibleForNewRequests == false ||
            data?.financialWarningCode == 'allowance_limit_exhausted' ||
            data?.financialWarningCode == 'deposit_below_minimum';

        return Column(
          children: [
            if (state.depositAccountStatus == BlocStatus.failed) ...[
              _errorBanner(
                ErrorMessageFormatter.format(
                  state.errorMessage,
                  fallback: 'تعذر تحميل بيانات مبلغ التأمين',
                ),
                () =>
                    context.read<ProfileBloc>().add(FetchDepositAccountEvent()),
              ),
              12.verticalSpace,
            ],
            if (warningText != null) ...[
              _financialWarningBanner(warningText, warningIsDanger),
              12.verticalSpace,
            ],
            _debtCard(
              WalletScreen.formatAmount(data?.displayAllowedDebtLimit ?? 0),
              currency,
              isLoading,
              subtitle: hasDepositBalance
                  ? 'غير مستخدم حالياً لأن رصيد الإيداع متاح.'
                  : null,
              isWarning:
                  !hasDepositBalance &&
                  ((data?.isAllowanceNearLimit ?? false) ||
                      (data?.isAllowanceLimitExhausted ?? false)),
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
                          : _statusBadge(accountStatus),
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

  Widget _debtCard(
    String amount,
    String currency,
    bool isLoading, {
    String? subtitle,
    bool isWarning = false,
  }) {
    final color = isWarning ? const Color(0xffDC2626) : const Color(0xff0F766E);

    return _card(
      borderColor: isWarning
          ? const Color(0xffFECACA)
          : const Color(0xffCCFBF1),
      child: Row(
        children: [
          _circleIcon(Icons.account_balance_wallet_outlined, color),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text('حد السماح', weight: FontWeight.w700, size: 18),
                4.verticalSpace,
                isLoading
                    ? _loadingLine(110.w)
                    : _text(
                        '$amount $currency',
                        color: isWarning
                            ? const Color(0xffB91C1C)
                            : const Color(0xff0F766E),
                        weight: FontWeight.w800,
                        size: 16,
                      ),
                if (!isLoading && subtitle != null) ...[
                  6.verticalSpace,
                  _text(subtitle, color: const Color(0xff6B7280), size: 13),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, Color color, bool isLoading) {
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

  Widget _financialWarningBanner(String message, bool isDanger) {
    final color = isDanger ? const Color(0xffB91C1C) : const Color(0xffB45309);
    final background = isDanger
        ? const Color(0xffFEF2F2)
        : const Color(0xffFFFBEB);
    final border = isDanger ? const Color(0xffFECACA) : const Color(0xffFDE68A);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.all(12.w),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isDanger ? Icons.error_outline : Icons.warning_amber_rounded,
            color: color,
          ),
          10.horizontalSpace,
          Expanded(child: _text(message, color: color, size: 14)),
        ],
      ),
    );
  }

  String? _financialWarningText(FetchDepositAccountUsecaseModel data) {
    final code = data.financialWarningCode?.trim().toLowerCase();
    switch (code) {
      case 'deposit_below_minimum':
        return 'رصيد الإيداع أقل من الحد الأدنى المطلوب. يرجى إيداع ${WalletScreen.formatAmount(data.minimumRequired ?? 0)} ل.س لتفعيل استقبال الطلبات.';
      case 'allowance_limit_exhausted':
        return 'وصل حد السماح إلى الصفر. يجب دفع المبلغ المستحق للإدارة لاستقبال طلبات جديدة.';
      case 'allowance_near_limit':
        return 'أوشك حد السماح على النفاد. يرجى دفع المبلغ المستحق للإدارة لتجنب إيقاف استقبال الطلبات.';
    }

    if (data.isAllowanceNearLimit == true) {
      return 'أوشك حد السماح على النفاد. يرجى دفع المبلغ المستحق للإدارة لتجنب إيقاف استقبال الطلبات.';
    }

    if (data.isAllowanceLimitExhausted == true) {
      return 'وصل حد السماح إلى الصفر. يجب دفع المبلغ المستحق للإدارة لاستقبال طلبات جديدة.';
    }

    return null;
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
