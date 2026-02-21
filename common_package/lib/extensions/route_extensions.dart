import 'package:flutter/material.dart';

extension RouteExtensions on BuildContext {
  void pop<T extends Object?>([T? result]) {
    Navigator.of(this).pop<T>(result);
  }

  void popUntil(RoutePredicate predicate) {
    Navigator.of(this).popUntil(predicate);
  }

  Future<T?>? pushRoute<T extends Object?>(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  }

  Future<T?>? pushRouteAndRemoveUntil<T extends Object?>(String routeName, {Object? arguments, bool Function(Route<dynamic>)? predicate}) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(routeName, predicate ?? (route) => false, arguments: arguments);
  }

  Future<T?>? pushRouteReplacement<T extends Object?, TO extends Object?>(String routeName, {Object? arguments, TO? result}) {
    return Navigator.of(this).pushReplacementNamed<T, TO>(routeName, arguments: arguments, result: result);
  }

  void popUntilRoute(String routeName) {
    Navigator.of(this).popUntil(ModalRoute.withName(routeName));
  }

  Future<T?>? popAndPushRoute<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments}) {
    return Navigator.of(this).popAndPushNamed<T, TO>(routeName, arguments: arguments, result: result);
  }

  bool canPop() {
    return Navigator.of(this).canPop();
  }

  void maybePop<T extends Object?>([T? result]) {
    Navigator.of(this).maybePop<T>(result);
  }
}
