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

class _MainScreenState extends State<MainScreen> {
  final MainNotifier mainNotifier = MainNotifier();

  @override
  void initState() {
    super.initState();
    if (widget.mainScreenParam != null) {
      mainNotifier.changePageIndex(mainNotifier.pageIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavBar(mainNotifier: mainNotifier),
      body: ValueListenableBuilder(
        valueListenable: mainNotifier.pageIndex,
        builder: (context, index, _) => [HomeScreen(), CalenderScreen(), OrdersScreen(), ProfileScreen()][index],
      ),
    );
  }
}

class MainScreenParam {
  final int returnedPageIndex;

  MainScreenParam({required this.returnedPageIndex});
}
