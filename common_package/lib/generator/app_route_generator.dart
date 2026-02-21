import 'dart:async';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

class AggregatingAppRouteBuilder implements Builder {
  @override
  final buildExtensions = const {
    r'$lib$': ['generated/app_routes.g.dart'],
  };

  static final _typeChecker = TypeChecker.fromUrl('package:common_package/annotations/auto_route_page.dart#AutoRoutePage');

  @override
  Future<void> build(BuildStep buildStep) async {
    final cases = <String>[];
    final imports = <String>{};

    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (input.path.contains('generated/')) continue;

      try {
        final library = await buildStep.resolver.libraryFor(input);
        final reader = LibraryReader(library);

        for (final element in reader.classes) {
          final annotation = _typeChecker.firstAnnotationOf(element);
          if (annotation == null) continue;

          final className = element.displayName;
          final readerAnnotation = ConstantReader(annotation);

          final customPath = readerAnnotation.peek('path')?.stringValue;

          final routePath = customPath ?? '/${className.replaceAll('Screen', '').toLowerCase()}';

          final importPath = input.path.replaceFirst('lib/', '');
          imports.add("import 'package:${buildStep.inputId.package}/$importPath';");

          final constructor = element.constructors.first;

          final parameters = constructor.formalParameters.where((p) => p.name != 'key').toList();

          if (parameters.isEmpty) {
            cases.add('''
      case '$routePath':
        return MaterialPageRoute(
          builder: (_) => $className(),
          settings: settings,
        );
''');
          } else {
            // Screen عندها parameters فعلية
            final paramAssignments = parameters
                .map((p) {
                  final paramName = p.name;
                  return "$paramName: $paramName";
                })
                .join(', ');

            final paramType = parameters.first.type.getDisplayString();

            cases.add('''
      case '$routePath':
        if (args is $paramType) {
          return MaterialPageRoute(
            builder: (_) => $className($paramAssignments),
            settings: settings,
          );
        }
        return _errorRoute(settings);
''');
          }
        }
      } catch (e) {
        // Skip files that cannot be parsed as libraries (e.g., part files, empty files, syntax errors)
        continue;
      }
    }

    final output =
        '''
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/material.dart';
${imports.join('\n')}

class GeneratedAppRoutes {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
${cases.join()}
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
''';

    final outputId = AssetId(buildStep.inputId.package, 'lib/generated/app_routes.g.dart');

    await buildStep.writeAsString(outputId, output);
  }
}
