import 'dart:io';

Future<void> main() async {
  final repoRoot = Directory.current.path;
  final tempRoot = await Directory.systemTemp.createTemp(
    'common_package_smoke_',
  );
  final appName = 'smoke_app';
  final appDirPath = '${tempRoot.path}${Platform.pathSeparator}$appName';

  try {
    await _run(
      'flutter',
      <String>['create', appName],
      workingDirectory: tempRoot.path,
    );

    final brickPath = _toPosixPath(
      '$repoRoot${Platform.pathSeparator}bricks${Platform.pathSeparator}apps${Platform.pathSeparator}app_bootstrap',
    );
    final masonFile = File('$appDirPath${Platform.pathSeparator}mason.yaml');
    masonFile.writeAsStringSync(
      'bricks:\n'
      '  app_bootstrap:\n'
      '    path: $brickPath\n',
    );

    await _run('mason', <String>['get'], workingDirectory: appDirPath);

    final firstRunArgs = <String>[
      'make',
      'app_bootstrap',
      '--on-conflict',
      'overwrite',
      '--app_name',
      'Smoke App',
      '--org_identifier',
      'com.example.smoke',
      '--base_url',
      'https://api.example.com',
      '--default_locale',
      'en',
      '--enable_notifications',
      'false',
    ];

    final secondRunArgs = List<String>.from(firstRunArgs)
      ..[3] = 'skip';

    await _run('mason', firstRunArgs, workingDirectory: appDirPath);
    await _run('mason', secondRunArgs, workingDirectory: appDirPath);

    _validateNoDuplicates('$appDirPath${Platform.pathSeparator}pubspec.yaml');

    await _run('flutter', <String>['pub', 'get'], workingDirectory: appDirPath);
    await _run('flutter', <String>['analyze'], workingDirectory: appDirPath);
    await _run('flutter', <String>['test'], workingDirectory: appDirPath);

    stdout.writeln('Smoke test passed.');
  } finally {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  }
}

void _validateNoDuplicates(String pubspecPath) {
  final content = File(pubspecPath).readAsStringSync();

  _expectSingleMatch(
    content,
    RegExp(r'^ {2}common_package:$', multiLine: true),
    'common_package dependency',
  );
  _expectSingleMatch(
    content,
    RegExp(r'^ {2}build_runner:', multiLine: true),
    'build_runner dependency',
  );
  _expectSingleMatch(
    content,
    RegExp(r'^ {4}- assets/translations/$', multiLine: true),
    'assets/translations entry',
  );
}

void _expectSingleMatch(String source, RegExp pattern, String label) {
  final count = pattern.allMatches(source).length;
  if (count != 1) {
    throw StateError('Expected exactly one $label, found $count.');
  }
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  stdout.writeln('> $executable ${arguments.join(' ')}');
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  if (result.stdout is String && (result.stdout as String).isNotEmpty) {
    stdout.write(result.stdout);
  }
  if (result.stderr is String && (result.stderr as String).isNotEmpty) {
    stderr.write(result.stderr);
  }

  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      'Command failed with exit code ${result.exitCode}.',
      result.exitCode,
    );
  }
}

String _toPosixPath(String value) {
  return value.replaceAll('\\', '/');
}
