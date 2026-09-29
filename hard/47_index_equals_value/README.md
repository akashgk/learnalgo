# Index Equals Value

**Difficulty:** Hard | **Category:** Searching | **Pattern:** Binary search on a derived monotonic function

## The problem

Given a sorted array of **distinct** integers, return the **smallest** index `i` such that `array[i] == i`, or -1 if none exists.

```
[-5, -3, 0, 3, 4, 5, 9]  ->  3
[0, 1, 2, 3]             ->  0
[-1, 0, 1]               ->  -1
```

## Step 1: Linear scan

Check every index: O(n). The sorted input suggests something faster.

## Step 2: Find a monotonic quantity

Define `f(i) = array[i] - i`.

Because the values are **distinct integers** in increasing order, each step increases the value by **at least 1**: `array[i+1] >= array[i] + 1`. Therefore `f(i+1) = array[i+1] - (i+1) >= array[i] + 1 - i - 1 = f(i)`. So `f` is **non-decreasing**.

We want the first index where `f(i) == 0`. On a non-decreasing function, "the first index where f reaches 0" is a **lower-bound** binary search:

- `f(mid) < 0` (`array[mid] < mid`): every index to the left also has `f < 0`: go right.
- `f(mid) >= 0`: the first zero, if any, is at `mid` or to its left. If `f(mid) == 0`, record `mid` as a candidate; go left to look for a smaller one.

## Step 3: The code

<!-- CODE:START -->

Full source: [`index_equals_value.dart`](index_equals_value.dart) (run it with `dart run`).

```dart
// Index Equals Value: sorted array of DISTINCT integers; return the smallest i with a[i] == i,
// or -1. a[i] - i is non-decreasing, so binary search for the first zero.
// O(log n) time, O(1) space.

int indexEqualsValue(List<int> array) {
  var lo = 0, hi = array.length - 1, answer = -1;
  while (lo <= hi) {
    final mid = lo + (hi - lo) ~/ 2;
    if (array[mid] < mid) {
      lo = mid + 1;
    } else {
      if (array[mid] == mid) answer = mid; // candidate; keep looking left for a smaller one
      hi = mid - 1;
    }
  }
  return answer;
}
```

<!-- CODE:END -->

### Walkthrough

- `answer` holds the best (smallest) index found so far.
- `array[mid] < mid` means go right.
- Otherwise, record a match if exact, and keep searching left (`hi = mid - 1`).

## Step 4: Dry run: `[-5, -3, 0, 3, 4, 5, 9]`

`f = array[i] - i = [-5, -4, -2, 0, 0, 0, 3]` (non-decreasing, as promised).

| lo | hi | mid | array[mid] | action | answer |
|---|---|---|---|---|---|
| 0 | 6 | 3 | 3 | equal: record, go left | 3 |
| 0 | 2 | 1 | -3 | < 1: go right | 3 |
| 2 | 2 | 2 | 0 | < 2: go right | 3 |
| 3 | 2 | | stop | | **3** |

## Complexity

- **Time: O(log n)**.
- **Space: O(1)**.

## Why "distinct" matters

With duplicates, `f` is no longer monotonic: `[2, 2, 2]` gives `f = [2, 1, 0]`, decreasing. Binary search breaks. A skip-ahead recursion still works but is O(n) in the worst case. Always check which property of the input the algorithm relies on.

## Common mistakes

- Returning the first match found by binary search (may not be the smallest index).
- Using this on arrays with duplicates.

## Follow-ups

1. **Cracking the Coding Interview 10.3 (Magic Index)** and **Fixed Point (LeetCode #1064).**
2. **Binary search on any monotonic predicate:** "the first day you can finish", "the minimum speed that works" (Koko Eating Bananas, #875). Same pattern.

## What to remember

Binary search works on any monotonic function, not only on raw sorted values. Look for a derived quantity (like `array[i] - i`) that is monotonic.
