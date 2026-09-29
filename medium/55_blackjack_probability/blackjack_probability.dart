// Blackjack Probability: draw cards 1..10 uniformly (infinite deck). Stop once hand >= target - 4.
// Bust if hand > target. Return P(bust) rounded to 3 decimals.
// Memoized recursion over hand values. O(target) states * 10 = O(target) time and space.

double blackjackProbability(int target, int startingHand) {
  final memo = <int, double>{};

  double bust(int hand) {
    if (hand > target) return 1;
    if (hand >= target - 4) return 0;
    return memo[hand] ??= [for (var card = 1; card <= 10; card++) bust(hand + card)]
            .reduce((a, b) => a + b) /
        10;
  }

  return (bust(startingHand) * 1000).round() / 1000;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(blackjackProbability(21, 15), 0.45);
  check(blackjackProbability(21, 21), 0.0);
  check(blackjackProbability(21, 22), 1.0);
}
