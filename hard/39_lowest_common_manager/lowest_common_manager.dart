// Lowest Common Manager in an org chart (n-ary tree, no parent pointers).
// Post-order: each subtree reports how many of the two reports it contains; the first node
// whose subtree contains both is the answer. O(n) time, O(d) space.

class OrgChart {
  OrgChart(this.name, [List<OrgChart>? directReports]) : directReports = directReports ?? [];
  final String name;
  final List<OrgChart> directReports;
}

OrgChart getLowestCommonManager(OrgChart topManager, OrgChart reportOne, OrgChart reportTwo) {
  OrgChart? answer;

  int countReports(OrgChart manager) {
    var count = 0;
    for (final report in manager.directReports) {
      count += countReports(report);
      if (answer != null) return 2; // already found deeper: stop exploring
    }
    if (identical(manager, reportOne)) count++;
    if (identical(manager, reportTwo)) count++;
    if (count == 2) answer ??= manager;
    return count;
  }

  countReports(topManager);
  return answer!;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final e = OrgChart('E'), f = OrgChart('F'), g = OrgChart('G');
  final h = OrgChart('H'), i = OrgChart('I');
  final d = OrgChart('D', [h, i]);
  final b = OrgChart('B', [d, e]), c = OrgChart('C', [f, g]);
  final a = OrgChart('A', [b, c]);
  check(getLowestCommonManager(a, e, i).name, 'B');
  check(getLowestCommonManager(a, h, g).name, 'A');
  check(getLowestCommonManager(a, d, i).name, 'D'); // a manager can be one of the reports
  check(getLowestCommonManager(a, f, f).name, 'F');
}
