// Palindrome Partitioning Min Cuts: fewest cuts so every piece is a palindrome.
// Expand around centers to mark palindromes while computing cuts[end] in one O(n^2) pass.
// O(n^2) time, O(n) space.

int palindromePartitioningMinCuts(String string) {
  final n = string.length;
  if (n == 0) return 0;
  // cuts[i] = min cuts for the prefix string[0..i] (inclusive). Worst case: i cuts.
  final cuts = List<int>.generate(n, (i) => i);
  void expand(int lo, int hi) {
    while (lo >= 0 && hi < n && string[lo] == string[hi]) {
      // string[lo..hi] is a palindrome: the prefix ending at hi can end with this piece.
      final candidate = lo == 0 ? 0 : cuts[lo - 1] + 1;
      if (candidate < cuts[hi]) cuts[hi] = candidate;
      lo--;
      hi++;
    }
  }

  for (var center = 0; center < n; center++) {
    expand(center, center); // odd length
    expand(center, center + 1); // even length
  }
  return cuts[n - 1];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(palindromePartitioningMinCuts('noonabbad'), 2); // noon | abba | d
  check(palindromePartitioningMinCuts('a'), 0);
  check(palindromePartitioningMinCuts('abc'), 2);
  check(palindromePartitioningMinCuts('racecar'), 0);
  check(palindromePartitioningMinCuts('aab'), 1);
}
