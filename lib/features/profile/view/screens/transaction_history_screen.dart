import 'package:common_package/annotations/auto_route_page.dart';
import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/core/di/injection.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_disputes_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/profile_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/bloc/profile_bloc.dart';
import '../widgets/transaction_app_bar.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_tab_bar.dart';

@AutoRoutePage()
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final ProfileNotifier profileNotifier = ProfileNotifier();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      lazy: false,
      create: (context) => getIt<ProfileBloc>()..add(FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1))),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TransactionAppBar(),
              SizedBox(height: 20),
              TransactionTabBar(profileNotifier: profileNotifier),
              SizedBox(height: 11),
              Expanded(
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  buildWhen: (previous, current) => previous.disputesUsecase != current.disputesUsecase,
                  builder: (context, state) {
                    return state.disputesUsecase!.builder(
                      loadingWidget: Padding(
                        padding: EdgeInsetsDirectional.only(top: 40),
                        child: Center(child: CircularProgressIndicator.adaptive()),
                      ),
                      emptyWidget: AppText.labelMedium('السجل فارغ', fontWeight: FontWeight.w400),
                      successWidget: () {
                        return ValueListenableBuilder(
                          valueListenable: profileNotifier.status,
                          builder: (context, status, _) => ListView.separated(
                            padding: EdgeInsetsDirectional.symmetric(horizontal: 24),
                            itemBuilder: (context, index) {
                              if (state.disputesUsecase!.length <= index) {
                                if (state.disputesUsecase!.length == index) {
                                  context.read<ProfileBloc>().add(
                                    FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: status)),
                                  );
                                }
                                return SizedBox(width: 30, height: 30, child: FittedBox(child: CircularProgressIndicator.adaptive(strokeWidth: 3)));
                              }
                              return TransactionCard(
                                type: state.disputesUsecase!.list[index].status == 'open'
                                    ? TransactionCardType.open
                                    : state.disputesUsecase!.list[index].status == 'closed'
                                    ? TransactionCardType.closed
                                    : state.disputesUsecase!.list[index].status == 'resolved'
                                    ? TransactionCardType.resolved
                                    : TransactionCardType.underReview,
                                title: state.disputesUsecase!.list[index].category!,
                                id: state.disputesUsecase!.list[index].ticketNumber!,
                                disputeId: state.disputesUsecase!.list[index].id!,
                                date: state.disputesUsecase!.list[index].booking!.scheduledDate!,
                              );
                            },
                            separatorBuilder: (context, index) => SizedBox(height: 16),
                            itemCount: state.disputesUsecase!.listLength(1),
                          ),
                        );
                      },
                      onTapRetry: () {
                        profileNotifier.changeStatus('open');
                        context.read<ProfileBloc>().add(FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: 'open')));
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
