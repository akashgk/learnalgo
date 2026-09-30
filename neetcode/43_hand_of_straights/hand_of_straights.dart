// Hand of Straights: can the cards be split into groups of groupSize consecutive values?
// Greedy from the smallest card: it must START a group (nothing smaller can contain it), so consume
// smallest, smallest + 1, ..., smallest + groupSize - 1. O(n log n) time, O(n) space.

import 'dart:collection';

bool isNStraightHand(List<int> hand, int groupSize) {
  if (hand.length % groupSize != 0) return false;
  final count = SplayTreeMap<int, int>(); // sorted map: firstKey() is the smallest remaining card
  for (final c in hand) {
    count[c] = (count[c] ?? 0) + 1;
  }
  while (count.isNotEmpty) {
    final start = count.firstKey()!;
    for (var v = start; v < start + groupSize; v++) {
      final c = count[v];
      if (c == null) return false; // a gap: this group cannot be completed
      if (c == 1) {
        count.remove(v);
      } else {
        count[v] = c - 1;
      }
    }
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isNStraightHand([1, 2, 3, 6, 2, 3, 4, 7, 8], 3), true); // [1,2,3] [2,3,4] [6,7,8]
  check(isNStraightHand([1, 2, 3, 4, 5], 4), false); // 5 cards, groups of 4
  check(isNStraightHand([1, 1, 2, 2, 3, 3], 3), true);
  check(isNStraightHand([1, 2, 4, 5, 6, 7], 3), false); // 1, 2 need a 3
  check(isNStraightHand([8, 10, 12], 1), true);
}
