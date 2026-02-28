import 'package:common_package/common_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'core/routes/app_router.dart';
import 'features/auth/view/screens/login_screen.dart';
import 'features/main/view/screens/main_screen.dart';

class App extends StatelessWidget {
  const App({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'cleaning owner',
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: SharedPreferencesHelper.getData(key: 'token') != null ? const MainScreen() : const LoginScreen(),
      theme: ThemeData(
        fontFamily: 'cairo',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xff1E2A7B),
          onPrimary: Colors.white,
          secondary: Color(0xff6C63FF),
          onSecondary: Colors.white,
          error: Color(0xffD92341),
          onError: Colors.white,
          surface: Color(0xffF0F0F0),
          onSurface: Colors.white,
          primaryContainer: Color(0xff2EC4B6),
          onPrimaryContainer: Colors.white,
        ),
      ),
    );
  }
}
