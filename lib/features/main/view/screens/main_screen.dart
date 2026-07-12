import 'package:common_package/annotations/auto_route_page.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../../../core/widgets/worker_technical_support_call_button.dart';
import '../../../calender/view/screens/calender_screen.dart';
import '../../../home/view/screens/home_screen.dart';
import '../../../orders/view/screens/orders_screen.dart';
import '../../../profile/view/screens/profile_screen.dart';
import '../../navigation/main_tab_navigation.dart';
import '../widgets/main_persistent_bottom_nav_bar.dart';

@AutoRoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.mainScreenParam});

  final MainScreenParam? mainScreenParam;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final MainTabNavigation _tabNavigation;
  late final PersistentTabController _tabController;
  late final VoidCallback _ordersStatusListener;

  String? _ordersInitialStatus;
  int _ordersStatusRequestId = 0;

  @override
  void initState() {
    super.initState();
    _tabNavigation = MainTabNavigation.instance;
    final requestedIndex =
        widget.mainScreenParam?.returnedPageIndex ??
        _tabNavigation.currentIndex;
    _tabNavigation.configureInitialState(
      index: requestedIndex,
      ordersInitialStatus: widget.mainScreenParam?.ordersInitialStatus,
    );
    _ordersInitialStatus = _tabNavigation.consumePendingOrdersInitialStatus();
    if (_ordersInitialStatus != null) {
      _ordersStatusRequestId = 1;
    }

    _tabController = _tabNavigation.createController();
    _tabNavigation.attachController(_tabController);

    _ordersStatusListener = _handleOrdersStatusRequest;
    _tabNavigation.ordersStatusRequestIdListenable.addListener(
      _ordersStatusListener,
    );
  }

  void _handleOrdersStatusRequest() {
    final nextStatus = _tabNavigation.consumePendingOrdersInitialStatus();
    if (nextStatus == null || nextStatus.isEmpty || !mounted) return;
    setState(() {
      _ordersInitialStatus = nextStatus;
      _ordersStatusRequestId++;
    });
  }

  @override
  void dispose() {
    _tabNavigation.ordersStatusRequestIdListenable.removeListener(
      _ordersStatusListener,
    );
    _tabNavigation.detachController(_tabController);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView.custom(
      context,
      controller: _tabController,
      itemCount: 4,
      navBarHeight: 84,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      handleAndroidBackButtonPress: true,
      stateManagement: true,
      confineToSafeArea: true,
      screens: [
        const CustomNavBarScreen(screen: HomeScreen()),
        CustomNavBarScreen(screen: CalenderScreen()),
        CustomNavBarScreen(
          screen: OrdersScreen(
            initialStatus: _ordersInitialStatus,
            statusRequestId: _ordersStatusRequestId,
          ),
        ),
        const CustomNavBarScreen(screen: ProfileScreen()),
      ],
      customWidget: MainPersistentBottomNavBar(
        controller: _tabController,
        onItemSelected: (index) => _tabNavigation.jumpToTab(index),
        onSupportTap: () => launchSupportWhatsApp(context),
      ),
    );
  }
}

class MainScreenParam {
  final int returnedPageIndex;
  final String? ordersInitialStatus;

  MainScreenParam({required this.returnedPageIndex, this.ordersInitialStatus});
}
