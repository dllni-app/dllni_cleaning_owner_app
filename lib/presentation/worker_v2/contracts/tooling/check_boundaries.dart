// Run from the Flutter application root with:
// dart run lib/presentation/worker_v2/contracts/tooling/check_boundaries.dart
import 'dart:io';

final _directive = RegExp(r'''\b(?:import|export)\s+['"]([^'"]+)['"]''');

void main(List<String> args) {
  final root = Directory(
    args.isEmpty ? 'lib/presentation/worker_v2' : args.single,
  );
  if (!root.existsSync()) {
    stderr.writeln('Worker V2 root not found: ${root.path}');
    exitCode = 2;
    return;
  }
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();
  final violations = <String>[];

  for (final file in files) {
    final relative = file.absolute.uri.pathSegments;
    final owner = _featureName(relative);
    final inContract = relative.contains('contracts');
    for (final match in _directive.allMatches(file.readAsStringSync())) {
      final source = match.group(1)!;
      violations.addAll(
        forbiddenImportsForSection(
          section: owner == null
              ? (inContract ? 'contracts' : 'provider')
              : 'features',
          source: source,
        ).map((reason) => '${file.path}: $reason $source'),
      );
      final target = _targetSegments(file, source);
      if (target == null) continue;
      final legacy =
          target.contains('features') &&
          !target.contains('worker_v2') &&
          (target.contains('view') ||
              target.contains('presentation') ||
              target.contains('screens') ||
              owner != null ||
              inContract);
      if (legacy) {
        violations.add('${file.path}: legacy visual import $source');
      }
      final otherFeature = _featureName(target);
      if (otherFeature != null && otherFeature != owner) {
        final isPublicEntry = target.isNotEmpty && target.last == 'module.dart';
        if (!isPublicEntry || inContract) {
          violations.add('${file.path}: cross-feature private import $source');
        }
      }
      if (inContract &&
          (target.contains('data') ||
              (target.contains('worker_v2') &&
                  target.contains('integration')))) {
        violations.add(
          '${file.path}: pure contract imports implementation $source',
        );
      }
    }
  }
  if (violations.isNotEmpty) {
    for (final violation in violations) {
      stderr.writeln(violation);
    }
    stderr.writeln('FAIL: ${violations.length} forbidden import(s)');
    exitCode = 1;
  } else {
    stdout.writeln('PASS: ${files.length} Dart files; no forbidden imports');
  }
}

/// These rules are applied only to new feature consumers and pure contracts;
/// S03 transport and S00 root integration have their own declared boundaries.
List<String> forbiddenImportsForSection({
  required String section,
  required String source,
}) {
  if (section != 'features' && section != 'contracts') return const [];
  final violations = <String>[];
  if (source.startsWith('package:dio/') ||
      source.startsWith('package:get_it/') ||
      source.startsWith('package:injectable/') ||
      source.contains('/core/di/') ||
      source.contains('/core/network/') ||
      source.contains('/data/source/') ||
      source.contains('/data/repository/')) {
    violations.add('direct transport or DI import');
  }
  if (section == 'contracts' &&
      (source.startsWith('package:flutter/') ||
          source.startsWith('package:dio/') ||
          source.startsWith('package:get_it/'))) {
    violations.add('non-pure contract dependency');
  }
  return violations;
}

List<String>? _targetSegments(File file, String source) {
  if (source.startsWith('dart:') ||
      source.startsWith('package:flutter/') ||
      (source.startsWith('package:') &&
          !source.startsWith('package:dllni_cleaninig_owner_app/'))) {
    return null;
  }
  if (source.startsWith('package:')) {
    return source
        .replaceFirst('package:dllni_cleaninig_owner_app/', 'lib/')
        .split('/');
  }
  return file.absolute.uri.resolve(source).pathSegments;
}

String? _featureName(List<String> segments) {
  final v2 = segments.indexOf('worker_v2');
  if (v2 < 0 || v2 + 2 >= segments.length || segments[v2 + 1] != 'features') {
    return null;
  }
  return segments[v2 + 2];
}
