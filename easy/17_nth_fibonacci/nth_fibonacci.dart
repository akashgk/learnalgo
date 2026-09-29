// Nth Fibonacci (1-indexed: F(1) = 0, F(2) = 1).
// Iterative with two variables: O(n) time, O(1) space.

int getNthFib(int n) {
  if (n == 1) return 0;
  var (prev, curr) = (0, 1);
  for (var i = 3; i <= n; i++) {
    (prev, curr) = (curr, prev + curr);
  }
  return curr;
}

/// Memoized recursion, shown for comparison: O(n) time, O(n) space.
int getNthFibMemo(int n, [Map<int, int>? memo]) {
  memo ??= {1: 0, 2: 1};
  return memo[n] ??= getNthFibMemo(n - 1, memo) + getNthFibMemo(n - 2, memo);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(getNthFib(1), 0);
  check(getNthFib(2), 1);
  check(getNthFib(6), 5);
  check(getNthFibMemo(6), 5);
  check(getNthFib(50), 7778742049);
}
