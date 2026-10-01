# First Bad Version

**Difficulty:** Easy | **Category:** Binary Search | **Pattern:** First true of a monotone predicate | **Source:** LeetCode 278; Grind 75

## The problem

Versions `1..n`. Once a version is bad, every later version is bad too. Given `isBadVersion(v)`, find the **first** bad version while minimizing the number of calls.

```
n = 5, first bad = 4:  isBad: 1 F, 2 F, 3 F, 4 T, 5 T  ->  4
```

## Step 1: Linear scan

Check 1, 2, 3, ... until the first true: up to n calls. With n = 2^31 - 1, far too many.

## Step 2: Monotone predicate

The answers look like `F F F T T`: all falses, then all trues. Binary search finds the **boundary** in O(log n) calls.

The "first true" template (also used in more_problems 13 Koko Eating Bananas):

```
lo = 1, hi = n            // the answer is always in [lo, hi]
while lo < hi:
  mid = lo + (hi - lo) / 2
  if isBad(mid): hi = mid       // mid could be the first bad one: keep it
  else:          lo = mid + 1   // mid is good: the first bad one is after it
return lo
```

## Step 3: The overflow detail

`(lo + hi) / 2` overflows 32-bit integers when `lo + hi > 2^31 - 1`, which happens here (n can be 2^31 - 1). `lo + (hi - lo) / 2` never exceeds `hi`. In Dart, ints are 64-bit so it would not overflow, but interviewers expect you to know this (it was a real bug in Java's standard library binary search for years).

## Step 4: The code

<!-- CODE:START -->

Full source: [`first_bad_version.dart`](first_bad_version.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `isBadVersion` is passed in as a function, so the tests can count calls.
- The loop ends with `lo == hi`, the first bad version (it exists by the problem's guarantee).

## Step 5: Dry run

n = 5, first bad = 4:

| lo | hi | mid | isBad(mid) | action |
|---|---|---|---|---|
| 1 | 5 | 3 | false | lo = 4 |
| 4 | 5 | 4 | true | hi = 4 |
| 4 | 4 | | | return **4** |

Two calls.

## Complexity

- Time: **O(log n)** calls.
- Space: **O(1)**.

## Edge cases

- `n = 1`: return 1 without any call.
- First bad is version 1, or version n.

## Common mistakes

- `hi = mid - 1` when mid is bad (can skip the answer).
- `while (lo <= hi)` with `hi = mid` (infinite loop when `lo == hi` and mid is bad).
- `(lo + hi) / 2` overflow in fixed-width languages.

## Follow-ups you should be ready for

1. **Search Insert Position (LeetCode 35).** First index with `nums[i] >= target`: the same template.
2. **Git bisect.** This is exactly how `git bisect` finds the commit that introduced a bug.
3. **Unknown n.** Double the upper bound (1, 2, 4, ...) until a bad version is found, then binary search: O(log answer).

## What to remember

"F F F T T, find the first T" is the canonical binary search. Keep the answer inside `[lo, hi]`, use `hi = mid` on true and `lo = mid + 1` on false, and compute mid without overflow.
