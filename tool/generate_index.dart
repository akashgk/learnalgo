// Regenerates the problem index between the INDEX markers in the root README.md
// from each problem's README (title on line 1, metadata on line 3).
// Usage: dart run tool/generate_index.dart

import 'dart:io';

const _levels = {
  'easy': 'Easy',
  'medium': 'Medium',
  'hard': 'Hard',
  'very_hard': 'Very Hard',
  'more_problems': 'More Problems (Striver A2Z, NeetCode 150, LeetCode)',
  'neetcode': 'NeetCode 150 (the rest of the list; see neetcode/README.md for the full map)',
};

void main() {
  final buffer = StringBuffer();
  var total = 0;
  for (final MapEntry(key: dir, value: label) in _levels.entries) {
    final folders = Directory(dir).listSync().whereType<Directory>().toList()..sort((a, b) => a.path.compareTo(b.path));
    // The extra set mixes difficulties and sources, so it gets two more columns.
    final extra = dir == 'more_problems' || dir == 'neetcode';
    buffer
      ..writeln('### $label (${folders.length})')
      ..writeln()
      ..writeln(
        extra ? '| # | Problem | Difficulty | Category | Pattern | Source |' : '| # | Problem | Category | Pattern |',
      )
      ..writeln(extra ? '|---|---|---|---|---|---|' : '|---|---|---|---|');
    for (final folder in folders) {
      final lines = File('${folder.path}/README.md').readAsLinesSync();
      final title = lines[0].replaceFirst('# ', '');
      final meta = {
        for (final part in lines[2].split(' | '))
          if (part.contains(':** ')) part.substring(2, part.indexOf(':**')): part.substring(part.indexOf(':** ') + 4),
      };
      final name = folder.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final number = name.split('_').first;
      final link = '[$title]($dir/$name/)';
      buffer.writeln(
        extra
            ? '| $number | $link | ${meta['Difficulty']} | ${meta['Category']} | ${meta['Pattern']} | ${meta['Source']} |'
            : '| $number | $link | ${meta['Category']} | ${meta['Pattern']} |',
      );
      total++;
    }
    buffer.writeln();
  }

  final readme = File('README.md');
  final text = readme.readAsStringSync();
  const start = '<!-- INDEX:START -->', end = '<!-- INDEX:END -->';
  final updated = text.replaceRange(
    text.indexOf(start) + start.length,
    text.indexOf(end),
    '\n\nTotal: $total problems.\n\n$buffer',
  );
  readme.writeAsStringSync(updated);
  print('Indexed $total problems.');
}
