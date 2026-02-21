import 'package:build/build.dart';
import 'generator/app_route_generator.dart';

Builder appRouteBuilder(BuilderOptions options) => AggregatingAppRouteBuilder();
