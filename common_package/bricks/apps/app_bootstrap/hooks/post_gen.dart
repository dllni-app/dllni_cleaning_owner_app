import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final rootPath = Directory.current.path;

  logger.info('post_gen: patching pubspec.yaml and mason.yaml');

  _patchPubspec(rootPath: rootPath, logger: logger);
  _patchMasonConfig(rootPath: rootPath, logger: logger);

  logger.info('');
  logger.info('Next commands:');
  logger.info('1) flutter pub get');
  logger.info(
    '2) dart run build_runner build --delete-conflicting-outputs',
  );
  logger.info('3) flutter run');
}

void _patchPubspec({required String rootPath, required Logger logger}) {
  final pubspecFile = File('$rootPath${Platform.pathSeparator}pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    logger.warn('pubspec.yaml not found, skipping dependency patch.');
    return;
  }

  final commonPackagePath = _resolveCommonPackagePath(rootPath: rootPath);
  var content = pubspecFile.readAsStringSync();

  content = _upsertYamlSectionEntries(
    content: content,
    sectionName: 'dependencies',
    entries: <String, List<String>>{
      'common_package': <String>[
        '  common_package:',
        '    path: $commonPackagePath',
      ],
      'easy_localization': <String>['  easy_localization: ^3.0.8'],
      'flutter_bloc': <String>['  flutter_bloc: ^9.1.1'],
      'dio': <String>['  dio: ^5.9.1'],
      'injectable': <String>['  injectable: ^2.7.1+4'],
      'get_it': <String>['  get_it: ^8.2.0'],
      'firebase_core': <String>['  firebase_core: ^4.4.0'],
      'firebase_messaging': <String>['  firebase_messaging: ^16.1.1'],
      'awesome_notifications': <String>[
        '  awesome_notifications: ^0.11.0',
      ],
    },
  );

  content = _upsertYamlSectionEntries(
    content: content,
    sectionName: 'dev_dependencies',
    entries: <String, List<String>>{
      'build_runner': <String>['  build_runner: ^2.7.1'],
    },
  );

  content = _ensureFlutterAssets(content);

  pubspecFile.writeAsStringSync(content);
  logger.info('Patched pubspec.yaml');
}

void _patchMasonConfig({required String rootPath, required Logger logger}) {
  final masonFile = File('$rootPath${Platform.pathSeparator}mason.yaml');
  if (!masonFile.existsSync()) {
    masonFile.writeAsStringSync(
      'bricks:\n'
      '  feature:\n'
      '    path: ../common_package/bricks/features/feature\n',
    );
    logger.info('Created mason.yaml with feature brick.');
    return;
  }

  var content = masonFile.readAsStringSync();
  content = _upsertYamlSectionEntries(
    content: content,
    sectionName: 'bricks',
    entries: <String, List<String>>{
      'feature': <String>[
        '  feature:',
        '    path: ../common_package/bricks/features/feature',
      ],
    },
  );
  masonFile.writeAsStringSync(content);
  logger.info('Patched mason.yaml with feature brick.');
}

String _upsertYamlSectionEntries({
  required String content,
  required String sectionName,
  required Map<String, List<String>> entries,
}) {
  final lines = const LineSplitter().convert(content);
  final mutable = List<String>.from(lines);
  final sectionLine = '$sectionName:';

  var sectionStart = _findLineIndex(mutable, sectionLine);
  if (sectionStart == -1) {
    if (mutable.isNotEmpty && mutable.last.trim().isNotEmpty) {
      mutable.add('');
    }
    sectionStart = mutable.length;
    mutable.add(sectionLine);
  }

  var sectionEnd = _findSectionEnd(mutable, sectionStart);

  for (final entry in entries.entries) {
    final keyPattern = RegExp('^  ${RegExp.escape(entry.key)}:');
    final exists = mutable
        .sublist(sectionStart + 1, sectionEnd)
        .any((line) => keyPattern.hasMatch(line));

    if (exists) {
      continue;
    }

    mutable.insertAll(sectionEnd, entry.value);
    sectionEnd += entry.value.length;
  }

  return '${mutable.join('\n')}\n';
}

String _ensureFlutterAssets(String content) {
  final lines = const LineSplitter().convert(content);
  final mutable = List<String>.from(lines);

  var flutterStart = _findLineIndex(mutable, 'flutter:');
  if (flutterStart == -1) {
    if (mutable.isNotEmpty && mutable.last.trim().isNotEmpty) {
      mutable.add('');
    }
    mutable.addAll(<String>[
      'flutter:',
      '  assets:',
      '    - assets/translations/',
    ]);
    return '${mutable.join('\n')}\n';
  }

  final flutterEnd = _findSectionEnd(mutable, flutterStart);
  var assetsStart = -1;
  for (var i = flutterStart + 1; i < flutterEnd; i++) {
    if (mutable[i].trim() == 'assets:') {
      assetsStart = i;
      break;
    }
  }

  if (assetsStart == -1) {
    mutable.insertAll(flutterEnd, <String>[
      '  assets:',
      '    - assets/translations/',
    ]);
    return '${mutable.join('\n')}\n';
  }

  final assetsEnd = _findNestedSectionEnd(
    mutable,
    assetsStart,
    parentIndent: 2,
    childIndent: 4,
  );
  final hasTranslationsAsset = mutable
      .sublist(assetsStart + 1, assetsEnd)
      .any((line) => line.trim() == '- assets/translations/');

  if (!hasTranslationsAsset) {
    mutable.insert(assetsEnd, '    - assets/translations/');
  }

  return '${mutable.join('\n')}\n';
}

int _findLineIndex(List<String> lines, String exactLine) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_leadingSpaces(line) == 0 && line.trimRight() == exactLine) {
      return i;
    }
  }
  return -1;
}

int _findSectionEnd(List<String> lines, int sectionStart) {
  for (var i = sectionStart + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      continue;
    }
    if (!line.startsWith(' ')) {
      return i;
    }
  }
  return lines.length;
}

int _findNestedSectionEnd(
  List<String> lines,
  int sectionStart, {
  required int parentIndent,
  required int childIndent,
}) {
  for (var i = sectionStart + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      continue;
    }
    final indent = _leadingSpaces(line);
    if (indent <= parentIndent) {
      return i;
    }
    if (indent == childIndent &&
        line.trim().endsWith(':') &&
        !line.trim().startsWith('-')) {
      return i;
    }
  }
  return lines.length;
}

int _leadingSpaces(String line) {
  var count = 0;
  while (count < line.length && line[count] == ' ') {
    count++;
  }
  return count;
}

String _resolveCommonPackagePath({required String rootPath}) {
  final lockFileCandidates = <String>[
    '$rootPath${Platform.pathSeparator}mason-lock.json',
    '$rootPath${Platform.pathSeparator}.mason${Platform.pathSeparator}mason-lock.json',
  ];

  File? existingLockFile;
  for (final path in lockFileCandidates) {
    final file = File(path);
    if (file.existsSync()) {
      existingLockFile = file;
      break;
    }
  }

  if (existingLockFile == null) {
    return '../common_package';
  }

  try {
    final decoded = jsonDecode(existingLockFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      return '../common_package';
    }

    final bricks = decoded['bricks'];
    if (bricks is! Map<String, dynamic>) {
      return '../common_package';
    }

    final appBootstrap = bricks['app_bootstrap'];
    if (appBootstrap is! Map<String, dynamic>) {
      return '../common_package';
    }

    final brickPath = appBootstrap['path'];
    if (brickPath is! String || brickPath.trim().isEmpty) {
      return '../common_package';
    }

    final normalizedPath = brickPath.replaceAll('\\', '/');
    const suffix = '/bricks/apps/app_bootstrap';
    if (normalizedPath.endsWith(suffix)) {
      return normalizedPath.substring(0, normalizedPath.length - suffix.length);
    }
  } catch (_) {
    return '../common_package';
  }

  return '../common_package';
}
