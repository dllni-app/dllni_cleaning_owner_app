import 'package:common_package/common_package.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/domain/usecases/fetch_disputes_usecase_use_case.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/bloc/profile_bloc.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/manager/profile_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';

class TransactionTabBar extends StatefulWidget {
  const TransactionTabBar({super.key, required this.profileNotifier});

  final ProfileNotifier profileNotifier;

  @override
  State<TransactionTabBar> createState() => _TransactionTabBarState();
}

class _TransactionTabBarState extends State<TransactionTabBar> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 4, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      isScrollable: false,
      onTap: (i) {
        if (i == 0) {
          context.read<ProfileBloc>().add(FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: 'open'), isReload: true));
        }
        if (i == 1) {
          context.read<ProfileBloc>().add(
            FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: 'under_review'), isReload: true),
          );
        }
        if (i == 2) {
          context.read<ProfileBloc>().add(FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: 'resolved'), isReload: true));
        }
        if (i == 3) {
          context.read<ProfileBloc>().add(FetchDisputesUsecaseEvent(params: FetchDisputesUsecaseParams(page: 1, status: 'closed'), isReload: true));
        }
      },
      dividerHeight: .1,
      tabAlignment: TabAlignment.center,
      indicatorColor: context.primary,
      controller: _tabController,
      labelPadding: EdgeInsetsDirectional.symmetric(vertical: 3, horizontal: 20),
      tabs: [AppText.labelLarge('مفتوحة'), AppText.labelLarge('في المراجعة'), AppText.labelLarge('محلولة'), AppText.labelLarge('مغلقة')],
      labelColor: Colors.black,
      indicator: MaterialIndicator(
        height: 2,
        topLeftRadius: 8,
        topRightRadius: 8,
        bottomLeftRadius: 8,
        bottomRightRadius: 8,
        tabPosition: TabPosition.bottom,
        color: context.primary,
      ),
    );
  }
}
