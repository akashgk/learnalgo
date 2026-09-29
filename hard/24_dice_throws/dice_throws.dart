// Dice Throws: number of ways to roll `numDice` dice with `numSides` sides summing to target.
// DP over dice with a rolling array. O(d * t * s) time, O(t) space.
// (A sliding-window sum makes it O(d * t).)

int diceThrows(int numDice, int numSides, int target) {
  var ways = List<int>.filled(target + 1, 0)..[0] = 1; // 0 dice: one way to make 0
  for (var d = 1; d <= numDice; d++) {
    final next = List<int>.filled(target + 1, 0);
    for (var t = 1; t <= target; t++) {
      for (var face = 1; face <= numSides && face <= t; face++) {
        next[t] += ways[t - face];
      }
    }
    ways = next;
  }
  return ways[target];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(diceThrows(2, 6, 7), 6);
  check(diceThrows(1, 6, 7), 0);
  check(diceThrows(3, 4, 3), 1);
  check(diceThrows(2, 2, 3), 2);
}
