// First Bad Version: versions 1..n; once a version is bad, every later version is bad.
// Find the first bad one with as few isBadVersion calls as possible.
// Binary search for the first true of a monotone predicate. O(log n) calls.

int firstBadVersion(int n, bool Function(int) isBadVersion) {
  var lo = 1, hi = n; // the answer is in [lo, hi]
  while (lo < hi) {
    final mid = lo + (hi - lo) ~/ 2; // avoids overflow of lo + hi in 32-bit languages
    if (isBadVersion(mid)) {
      hi = mid; // mid might be the first bad one
    } else {
      lo = mid + 1; // the first bad one is after mid
    }
  }
  return lo;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  var calls = 0;
  bool bad(int v) {
    calls++;
    return v >= 4;
  }

  check(firstBadVersion(5, bad), 4);
  check(calls <= 3, true); // ceil(log2 5) = 3
  check(firstBadVersion(1, (v) => true), 1);
  check(firstBadVersion(2147483647, (v) => v >= 2147483647), 2147483647);
  check(firstBadVersion(10, (v) => v >= 1), 1);
}
