// Min Rewards: students in a line with distinct scores. Everyone gets >= 1 reward, and a
// student with a higher score than an adjacent student gets strictly more than them.
// Two sweeps (left-to-right, right-to-left). O(n) time, O(n) space.

int minRewards(List<int> scores) {
  final rewards = List<int>.filled(scores.length, 1);
  for (var i = 1; i < scores.length; i++) {
    if (scores[i] > scores[i - 1]) rewards[i] = rewards[i - 1] + 1;
  }
  for (var i = scores.length - 2; i >= 0; i--) {
    if (scores[i] > scores[i + 1] && rewards[i] <= rewards[i + 1]) {
      rewards[i] = rewards[i + 1] + 1;
    }
  }
  return rewards.fold(0, (a, b) => a + b);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(minRewards([8, 4, 2, 1, 3, 6, 7, 9, 5]), 25);
  check(minRewards([1]), 1);
  check(minRewards([5, 10]), 3);
  check(minRewards([4, 3, 2, 1]), 10);
}
