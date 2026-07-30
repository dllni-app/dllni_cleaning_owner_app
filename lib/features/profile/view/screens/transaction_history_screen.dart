import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/data/models/fetch_deposit_transactions_usecase_model.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_deposit_transactions_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'wallet_screen.dart';
import '../widgets/transaction_app_bar.dart';

@AutoRoutePage()
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  static const int _perPage = 20;
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (context) => getIt<ProfileBloc>()
        ..add(
          FetchDepositTransactionsEvent(
            params: FetchDepositTransactionsParams(perPage: _perPage),
            clearTypeFilter: true,
            isReload: true,
          ),
        ),
      child: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const TransactionAppBar(),
                const SizedBox(height: 16),
                _TransactionTypeTabs(
                  selectedType: _typeFilter,
                  onSelected: (type) {
                    setState(() => _typeFilter = type);
                    context.read<ProfileBloc>().add(
                      FetchDepositTransactionsEvent(
                        params: FetchDepositTransactionsParams(
                          perPage: _perPage,
                          type: type,
                        ),
                        typeFilter: type,
                        clearTypeFilter: type == null,
                        isReload: true,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Expanded(child: _TransactionList(typeFilter: _typeFilter)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionTypeTabs extends StatelessWidget {
  const _TransactionTypeTabs({
    required this.selectedType,
    required this.onSelected,
  });

  final String? selectedType;
  final ValueChanged<String?> onSelected;

  static const _filters = <({String label, String? type})>[
    (label: 'الكل', type: null),
    (label: 'إيداع', type: 'deposit'),
    (label: 'دين', type: 'debt'),
    (label: 'استرداد', type: 'refund'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = filter.type == selectedType;
          return ChoiceChip(
            selected: selected,
            label: Text(filter.label),
            onSelected: (_) => onSelected(filter.type),
            selectedColor: context.primary,
            labelStyle: TextStyle(
              color: selected ? context.onPrimary : const Color(0xff111827),
              fontWeight: FontWeight.w700,
            ),
            side: BorderSide(
              color: selected ? context.primary : const Color(0xffE5E7EB),
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          );
        },
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.typeFilter});

  final String? typeFilter;

  bool _handleScroll(BuildContext context, ScrollNotification notification) {
    if (notification.metrics.pixels <
        notification.metrics.maxScrollExtent - 160) {
      return false;
    }

    final state = context.read<ProfileBloc>().state;
    final pagination = state.depositTransactionsPagination;
    if (pagination.isEndPage ||
        pagination.status == BlocStatus.loading ||
        pagination.status == BlocStatus.init) {
      return false;
    }

    context.read<ProfileBloc>().add(
      FetchDepositTransactionsEvent(
        params: FetchDepositTransactionsParams(
          perPage: _TransactionHistoryScreenState._perPage,
          type: typeFilter,
        ),
        typeFilter: typeFilter,
        loadMore: true,
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) =>
          previous.depositTransactionsPagination !=
              current.depositTransactionsPagination ||
          previous.depositTransactionsTypeFilter !=
              current.depositTransactionsTypeFilter,
      builder: (context, state) {
        final pagination = state.depositTransactionsPagination;
        final items = pagination.list;
        final loadingFirstPage =
            (pagination.status == BlocStatus.loading ||
                pagination.status == BlocStatus.init) &&
            items.isEmpty;

        if (loadingFirstPage) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (pagination.status == BlocStatus.failed && items.isEmpty) {
          return _MessageState(
            icon: Icons.error_outline,
            message: ErrorMessageFormatter.format(
              state.errorMessage,
              fallback: 'تعذر تحميل سجل المعاملات',
            ),
            actionLabel: 'إعادة المحاولة',
            onAction: () => context.read<ProfileBloc>().add(
              FetchDepositTransactionsEvent(
                params: FetchDepositTransactionsParams(
                  perPage: _TransactionHistoryScreenState._perPage,
                  type: typeFilter,
                ),
                typeFilter: typeFilter,
                clearTypeFilter: typeFilter == null,
                isReload: true,
              ),
            ),
          );
        }

        if (items.isEmpty) {
          return const _MessageState(
            icon: Icons.receipt_long_outlined,
            message: 'سجل المعاملات فارغ',
          );
        }

        final showFooter = pagination.status == BlocStatus.loading;
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) =>
              _handleScroll(context, notification),
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<ProfileBloc>().add(
                FetchDepositTransactionsEvent(
                  params: FetchDepositTransactionsParams(
                    perPage: _TransactionHistoryScreenState._perPage,
                    type: typeFilter,
                  ),
                  typeFilter: typeFilter,
                  clearTypeFilter: typeFilter == null,
                  isReload: true,
                ),
              );
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 24),
              itemCount: items.length + (showFooter ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  );
                }
                return _DepositTransactionCard(transaction: items[index]);
              },
            ),
          ),
        );
      },
    );
  }
}

class _DepositTransactionCard extends StatelessWidget {
  const _DepositTransactionCard({required this.transaction});

  final FetchDepositTransactionsUsecaseModelDataItem transaction;

  @override
  Widget build(BuildContext context) {
    final type = _normalizedType(transaction.type);
    final color = _typeColor(type);
    final amount = transaction.amount ?? 0;
    final amountPrefix = type == 'refund' ? '-' : '+';
    final currency = WalletScreen.resolveCurrencyLabel(null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withAlpha(28),
            child: Icon(_typeIcon(type), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyLarge(
                  _typeLabel(type),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff111827),
                ),
                const SizedBox(height: 4),
                AppText.bodySmall(
                  _formatDate(transaction.createdAt),
                  color: const Color(0xff6B7280),
                ),
                if ((transaction.reference ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText.bodySmall(
                    transaction.reference!.trim(),
                    color: const Color(0xff9CA3AF),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText.bodyLarge(
                '$amountPrefix${WalletScreen.formatAmount(amount.abs())} $currency',
                fontWeight: FontWeight.w800,
                color: color,
              ),
              const SizedBox(height: 4),
              AppText.bodySmall(
                '${WalletScreen.formatAmount(transaction.balanceAfter ?? 0)} $currency',
                color: const Color(0xff6B7280),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _normalizedType(String? type) {
    final value = (type ?? '').trim().toLowerCase();
    if (value == 'withdrawal' || value == 'withdraw') return 'refund';
    if (value == 'settlement' || value == 'commission') return 'debt';
    if (value == 'deposit' || value == 'debt' || value == 'refund') {
      return value;
    }
    return 'transaction';
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'deposit':
        return 'إيداع';
      case 'debt':
        return 'دين الإدارة';
      case 'refund':
        return 'استرداد';
      default:
        return 'معاملة مالية';
    }
  }

  static IconData _typeIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icons.south_west;
      case 'debt':
        return Icons.account_balance_wallet_outlined;
      case 'refund':
        return Icons.north_east;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  static Color _typeColor(String type) {
    switch (type) {
      case 'deposit':
        return const Color(0xff059669);
      case 'debt':
        return const Color(0xffDC2626);
      case 'refund':
        return const Color(0xff2563EB);
      default:
        return const Color(0xff6B7280);
    }
  }

  static String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '-';
    return DateFormat('yyyy-MM-dd', 'en').format(parsed);
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xff9CA3AF)),
            const SizedBox(height: 12),
            AppText.bodyLarge(
              message,
              textAlign: TextAlign.center,
              color: const Color(0xff6B7280),
              fontWeight: FontWeight.w600,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
