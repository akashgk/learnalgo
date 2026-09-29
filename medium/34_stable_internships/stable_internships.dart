// Stable Internships: Gale-Shapley stable matching with interns proposing.
// interns[i] = team preferences of intern i (best first); teams[t] = intern preferences.
// Returns [intern, team] pairs. O(n^2) time, O(n^2) space.

import 'dart:collection';

List<List<int>> stableInternships(List<List<int>> interns, List<List<int>> teams) {
  final n = interns.length;
  // rank[t][i] = position of intern i in team t's list (lower is better): O(1) comparisons.
  final rank = [
    for (final prefs in teams) {for (var pos = 0; pos < prefs.length; pos++) prefs[pos]: pos},
  ];
  final nextChoice = List<int>.filled(n, 0); // next team each intern will propose to
  final teamMatch = List<int?>.filled(n, null); // teamMatch[t] = intern currently held
  final free = Queue<int>.of(List.generate(n, (i) => i));

  while (free.isNotEmpty) {
    final intern = free.removeFirst();
    final team = interns[intern][nextChoice[intern]++];
    final current = teamMatch[team];
    if (current == null) {
      teamMatch[team] = intern;
    } else if (rank[team][intern]! < rank[team][current]!) {
      teamMatch[team] = intern;
      free.add(current); // bumped intern proposes to their next choice later
    } else {
      free.add(intern);
    }
  }
  return [
    for (var t = 0; t < n; t++) [teamMatch[t]!, t],
  ]..sort((a, b) => a[0] - b[0]);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

/// Independent verifier: no intern/team pair prefers each other over their assignment.
bool isStable(List<List<int>> matching, List<List<int>> interns, List<List<int>> teams) {
  final teamOf = {for (final [i, t] in matching) i: t};
  final internOf = {for (final [i, t] in matching) t: i};
  for (var i = 0; i < interns.length; i++) {
    for (final t in interns[i]) {
      if (t == teamOf[i]) break; // teams after this are worse for intern i
      if (teams[t].indexOf(i) < teams[t].indexOf(internOf[t]!)) return false;
    }
  }
  return true;
}

void main() {
  final interns = [
    [0, 1, 2],
    [0, 2, 1],
    [1, 2, 0],
  ];
  final teams = [
    [2, 1, 0],
    [1, 2, 0],
    [0, 2, 1],
  ];
  final result = stableInternships(interns, teams);
  // Trace: i0->t0, i1->t0 (t0 prefers i1, drops i0), i2->t1, i0->t1 (rejected), i0->t2.
  check(result, [
    [0, 2],
    [1, 0],
    [2, 1],
  ]);
  check(isStable(result, interns, teams), true);
  check(
    isStable(
      [
        [0, 0],
        [1, 1],
        [2, 2],
      ],
      interns,
      teams,
    ),
    false,
  );
  check(
    stableInternships(
      [
        [0],
      ],
      [
        [0],
      ],
    ),
    [
      [0, 0],
    ],
  );
}
