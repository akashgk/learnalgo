// Happy Number: repeatedly replace n by the sum of the squares of its digits. Happy if this reaches
// 1; otherwise it loops forever. Detect the loop with Floyd's fast/slow pointers (O(1) space).
// The sequence quickly drops below 243 (for n < 1000, the next value is at most 3 * 81), so the
// number of steps is O(log n) per iteration and bounded overall.

bool isHappy(int n) {
  var slow = n, fast = _next(n);
  while (fast != 1 && slow != fast) {
    slow = _next(slow);
    fast = _next(_next(fast));
  }
  return fast == 1;
}

int _next(int n) {
  var sum = 0;
  while (n > 0) {
    final d = n % 10;
    sum += d * d;
    n ~/= 10;
  }
  return sum;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isHappy(19), true); // 19 -> 82 -> 68 -> 100 -> 1
  check(isHappy(2), false); // falls into the cycle 4 -> 16 -> 37 -> 58 -> 89 -> 145 -> 42 -> 20 -> 4
  check(isHappy(1), true);
  check(isHappy(7), true);
}
