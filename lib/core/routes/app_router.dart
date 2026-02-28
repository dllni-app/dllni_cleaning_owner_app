import 'package:flutter/material.dart';

import '../../generated/app_routes.g.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return GeneratedAppRoutes.onGenerateRoute(settings);
  }
}
