import 'package:common_package/annotations/auto_route_page.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/manager/notifier/main_notifier.dart';
import 'package:flutter/material.dart';

import '../../../calender/view/screens/calender_screen.dart';
import '../../../home/view/screens/home_screen.dart';
import '../../../orders/view/screens/orders_screen.dart';
import '../../../profile/view/screens/profile_screen.dart';
import '../widgets/bottom_nav_bar.dart';

@AutoRoutePage()
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.mainScreenParam});

  final MainScreenParam? mainScreenParam;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(controller: controller),
      body: TabBarView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [HomeScreen(), CalenderScreen(), OrdersScreen(), ProfileScreen()],
      ),
    );
  }
}

class MainScreenParam {
  final int returnedPageIndex;

  MainScreenParam({required this.returnedPageIndex});
}
