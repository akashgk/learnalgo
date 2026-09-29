// Longest Balanced Substring of '(' and ')'. Two scans with counters (left-to-right and
// right-to-left) catch every balanced run. O(n) time, O(1) space.

int longestBalancedSubstring(String string) {
  int scan(bool leftToRight) {
    var open = 0, close = 0, best = 0;
    final n = string.length;
    for (var k = 0; k < n; k++) {
      final ch = string[leftToRight ? k : n - 1 - k];
      if (ch == '(') {
        open++;
      } else {
        close++;
      }
      if (open == close) {
        if (2 * close > best) best = 2 * close;
      } else if (leftToRight ? close > open : open > close) {
        open = close = 0; // prefix can no longer be balanced: restart
      }
    }
    return best;
  }

  final a = scan(true), b = scan(false);
  return a > b ? a : b;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestBalancedSubstring('(()))('), 4);
  check(longestBalancedSubstring('(()'), 2); // needs the right-to-left scan
  check(longestBalancedSubstring(''), 0);
  check(longestBalancedSubstring('()(()())'), 8);
  check(longestBalancedSubstring(')('), 0);
}
