// Tournament Winner
// Tally points per team in a map, tracking the leader as we go. O(n) time, O(k) space.

const homeTeamWon = 1;

String tournamentWinner(List<List<String>> competitions, List<int> results) {
  final points = <String, int>{};
  var leader = '';
  points[leader] = 0;
  for (var i = 0; i < competitions.length; i++) {
    final [home, away] = competitions[i];
    final winner = results[i] == homeTeamWon ? home : away;
    final score = points.update(winner, (p) => p + 3, ifAbsent: () => 3);
    if (score > points[leader]!) leader = winner;
  }
  return leader;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    tournamentWinner(
      [
        ['HTML', 'C#'],
        ['C#', 'Python'],
        ['Python', 'HTML'],
      ],
      [0, 0, 1],
    ),
    'Python',
  );
  check(
    tournamentWinner(
      [
        ['Bulls', 'Eagles'],
      ],
      [1],
    ),
    'Bulls',
  );
}
