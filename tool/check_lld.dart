// Verifies the code in every system_design/*/LLD.md.
// Each LLD.md contains exactly one ```dart block: a complete program whose main() runs self-checks.
// This tool extracts each block to build/lld_check/<folder>.dart, then checks that it is
// formatted, passes `dart analyze --fatal-infos` (with the repo's strict settings), and runs cleanly.
// Usage: dart run tool/check_lld.dart

import 'dart:io';

void main() {
  final outDir = Directory('build/lld_check');
  if (outDir.existsSync()) outDir.deleteSync(recursive: true);
  outDir.createSync(recursive: true);

  final folders = Directory('system_design').listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final files = <String>[];
  var problems = 0;
  for (final folder in folders) {
    final name = folder.uri.pathSegments.where((s) => s.isNotEmpty).last;
    for (final required in ['HLD.md', 'LLD.md']) {
      if (!File('${folder.path}/$required').existsSync()) {
        stderr.writeln('$name: missing $required');
        problems++;
      }
    }
    final lld = File('${folder.path}/LLD.md');
    if (!lld.existsSync()) continue;
    final blocks = RegExp(r'```dart\n([\s\S]*?)```').allMatches(lld.readAsStringSync()).toList();
    if (blocks.length != 1) {
      stderr.writeln('$name/LLD.md: expected exactly one ```dart block, found ${blocks.length}');
      problems++;
      continue;
    }
    final path = '${outDir.path}/$name.dart';
    File(path).writeAsStringSync(blocks.single.group(1)!);
    files.add(path);
  }

  ProcessResult run(List<String> args) => Process.runSync('dart', args);

  final format = run(['format', '--output=none', '--set-exit-if-changed', ...files]);
  if (format.exitCode != 0) {
    stderr.writeln('Unformatted LLD code (format the block in LLD.md):\n${format.stdout}');
    problems++;
  }
  final analyze = run(['analyze', '--fatal-infos', outDir.path]);
  if (analyze.exitCode != 0) {
    stderr.writeln('Analyzer issues in LLD code:\n${analyze.stdout}');
    problems++;
  }
  for (final path in files) {
    final result = run(['run', path]);
    if (result.exitCode != 0) {
      stderr.writeln('FAIL $path\n${result.stdout}\n${result.stderr}');
      problems++;
    }
  }
  print(problems == 0 ? 'All ${files.length} LLD programs formatted, analyzed and passing.' : '$problems problem(s).');
  if (problems > 0) exitCode = 1;
}
