// Run from the worker application root. Verifies literal S00 path ownership
// against the package manifest and optionally all changed worker files.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final manifestFile = File('../docs/cleaning-worker-rebuild/ownership.json');
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing package ownership manifest');
    exitCode = 2;
    return;
  }
  final data =
      jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  final sessions = data['sessions'] as Map<String, dynamic>;
  final claims = <String, String>{};
  for (final entry in sessions.entries) {
    final record = entry.value as Map<String, dynamic>;
    for (final claim in (record['owns'] as List).cast<String>()) {
      if (claims.containsKey(claim)) {
        stderr.writeln('Duplicate ownership: $claim');
        exitCode = 1;
      }
      claims[claim] = entry.key;
    }
  }
  final entries = claims.entries.toList();
  for (var i = 0; i < entries.length; i++) {
    for (var j = i + 1; j < entries.length; j++) {
      final a = entries[i].key;
      final b = entries[j].key;
      if (a.startsWith(b) || b.startsWith(a)) {
        stderr.writeln(
          'Overlapping ownership: $a (${entries[i].value}) / $b (${entries[j].value})',
        );
        exitCode = 1;
      }
    }
  }

  final git = Process.runSync('git', [
    'status',
    '--porcelain=v1',
    '--untracked-files=all',
  ]);
  if (git.exitCode != 0) {
    stderr.writeln('git status failed: ${git.stderr}');
    exitCode = 2;
    return;
  }
  final changed = (git.stdout as String)
      .split(RegExp(r'\r?\n'))
      .where((line) => line.length >= 4)
      .map((line) => line.substring(3).replaceAll('\\', '/'));
  var s00Count = 0;
  for (final path in changed) {
    final normalized = 'dllni_cleaning_owner_app/$path';
    final owner = entries.where(
      (claim) => claim.key.endsWith('/')
          ? normalized.startsWith(claim.key)
          : normalized == claim.key,
    );
    if (owner.isEmpty) {
      stderr.writeln('UNOWNED changed file: $normalized');
      exitCode = 1;
    } else if (owner.single.value != 'S00' && args.contains('--s00-only')) {
      stderr.writeln(
        'Foreign writer file present at S00-only checkpoint: $normalized (${owner.single.value})',
      );
      exitCode = 1;
    } else if (owner.single.value == 'S00') {
      s00Count++;
    }
  }
  if (exitCode == 0) {
    stdout.writeln(
      'PASS: ${entries.length} ownership claims with no overlap; $s00Count S00 changed paths owned',
    );
  }
}
