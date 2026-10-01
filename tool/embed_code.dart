// Copies each problem's solution code (everything above the test harness, i.e. before
// `void check(`) into its README between the CODE markers, so the README always shows
// exactly the code that is tested.
// Usage: dart run tool/embed_code.dart            (update all READMEs)
//        dart run tool/embed_code.dart --check    (exit 1 if any README is out of date)

import 'dart:io';

const start = '<!-- CODE:START -->';
const end = '<!-- CODE:END -->';

void main(List<String> args) {
  final checkOnly = args.contains('--check');
  var stale = 0, updated = 0;
  for (final level in ['easy', 'medium', 'hard', 'very_hard', 'more_problems', 'neetcode', 'blind75_grind75']) {
    final folders = Directory(level).listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final folder in folders) {
      final dart = folder.listSync().whereType<File>().firstWhere((f) => f.path.endsWith('.dart'));
      final readme = File('${folder.path}/README.md');
      final text = readme.readAsStringSync();
      if (!text.contains(start)) continue;
      final source = dart.readAsStringSync();
      final cut = source.indexOf('void check(');
      final code = (cut == -1 ? source : source.substring(0, cut)).trimRight();
      final fileName = dart.uri.pathSegments.last;
      final block = '\n\nFull source: [`$fileName`]($fileName) (run it with `dart run`).\n\n```dart\n$code\n```\n\n';
      final next = text.replaceRange(text.indexOf(start) + start.length, text.indexOf(end), block);
      if (next != text) {
        stale++;
        if (!checkOnly) {
          readme.writeAsStringSync(next);
          updated++;
        }
      }
    }
  }
  if (checkOnly) {
    print(
      stale == 0
          ? 'All embedded code is up to date.'
          : '$stale README(s) have stale code. Run: dart run tool/embed_code.dart',
    );
    if (stale > 0) exitCode = 1;
  } else {
    print('Updated $updated README(s).');
  }
}
