// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/material.dart';
import 'package:dllni_cleaninig_owner_app/features/main/view/screens/main_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/orders/view/screens/order_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/transaction_details_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/transaction_history_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/update_profile_screen.dart';
import 'package:dllni_cleaninig_owner_app/features/profile/view/screens/working_time_screen.dart';

import '../features/profile/data/models/fetch_worker_profile_usecase_model.dart';

class GeneratedAppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/main':
        if (args is MainScreenParam?) {
          return MaterialPageRoute(
            builder: (_) => MainScreen(mainScreenParam: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);
      case '/orderdetails':
        if (args is OrderDetailsScreenParams) {
          return MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(params: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);
      case '/transactiondetails':
        if (args is TransactionDetailsScreenParam) {
          return MaterialPageRoute(
            builder: (_) => TransactionDetailsScreen(params: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);
      case '/transactionhistory':
        return MaterialPageRoute(
          builder: (_) => TransactionHistoryScreen(),
          settings: settings,
        );
      case '/updateprofile':
        if (args is UpdateProfileScreenParams) {
          return MaterialPageRoute(
            builder: (_) => UpdateProfileScreen(params: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);
      case '/workingtime':
        if (args is FetchWorkerProfileUsecaseModelDataDefaultWorkingHours) {
          return MaterialPageRoute(
            builder: (_) => WorkingTimeScreen(data: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);

    }

    return null;
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(child: Text('Route Error')),
      ),
      settings: settings,
    );
  }
}
