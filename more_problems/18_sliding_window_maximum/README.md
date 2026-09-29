# Sliding Window Maximum

**Difficulty:** Hard | **Category:** Queues / Sliding window | **Pattern:** Monotonic deque | **Source:** LeetCode 239; Striver A2Z, NeetCode 150

## The problem

Return the maximum of every contiguous window of size `k`.

```
[1, 3, -1, -3, 5, 3, 6, 7], k = 3  ->  [3, 3, 5, 5, 6, 7]
```

## Step 1: Brute force

For each of the `n - k + 1` windows, scan `k` elements: **O(nk)**. With n = 10^5 and k = 5 * 10^4, that is too slow.

## Step 2: Why a running max does not work

A sum can be slid: add the new element, subtract the old one. A maximum cannot: when the maximum leaves the window, you do not know the next maximum without rescanning. We need a structure that knows the **next** candidates.

## Step 3: A heap works, but is not optimal

Keep a max-heap of `(value, index)`. At each step push the new element; pop the top while its index is outside the window (lazy deletion). O(n log n). Say it as a stepping stone.

## Step 4: Which elements can ever be a maximum?

Suppose `i < j` are both in the window and `nums[i] <= nums[j]`. Then `i` can **never** be the maximum of any current or future window: every window that contains `i` from now on also contains `j` (j is newer, so it stays longer), and `nums[j]` is at least as large. `i` is useless, and we can delete it.

After deleting all useless elements, the remaining ones have **strictly decreasing values** from oldest to newest. The oldest remaining one is the maximum of the window. This is a **monotonic deque** (double-ended queue):

- **Back:** when a new element arrives, pop every element at the back with a value `<=` the new one (they just became useless). Then push the new index.
- **Front:** if the front index has left the window, pop it.
- The answer for the window is the value at the front.

## Step 5: The code

<!-- CODE:START -->

Full source: [`sliding_window_maximum.dart`](sliding_window_maximum.dart) (run it with `dart run`).

```dart
// Sliding Window Maximum: the maximum of every window of size k.
// Monotonic deque of indices whose values decrease from front to back. O(n) time, O(k) space.

import 'dart:collection';

List<int> maxSlidingWindow(List<int> nums, int k) {
  final dq = ListQueue<int>(); // indices; nums[dq.first] is the current window's maximum
  final result = <int>[];
  for (var i = 0; i < nums.length; i++) {
    // Drop the front index once it falls out of the window [i - k + 1, i].
    if (dq.isNotEmpty && dq.first <= i - k) dq.removeFirst();
    // A smaller value behind nums[i] can never be a maximum again: nums[i] is newer and larger.
    while (dq.isNotEmpty && nums[dq.last] <= nums[i]) {
      dq.removeLast();
    }
    dq.addLast(i);
    if (i >= k - 1) result.add(nums[dq.first]);
  }
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- The deque stores **indices**, not values, so we can tell when the front leaves the window.
- `if (dq.first <= i - k) dq.removeFirst();` handles expiry. One check is enough, because the window moves by one and at most one index expires per step.
- `while (nums[dq.last] <= nums[i]) dq.removeLast();` enforces the decreasing order. Using `<=` (not `<`) also drops equal older values, which is fine: the newer equal value lives longer.
- A result is produced once the first full window is formed (`i >= k - 1`).

## Step 6: Dry run

`[1, 3, -1, -3, 5, 3, 6, 7]`, k = 3. The deque is shown as `index:value`:

| i | nums[i] | deque after step | output |
|---|---|---|---|
| 0 | 1 | 0:1 | |
| 1 | 3 | 1:3 (1 popped) | |
| 2 | -1 | 1:3, 2:-1 | 3 |
| 3 | -3 | 1:3, 2:-1, 3:-3 | 3 |
| 4 | 5 | 4:5 (1 expired, then -1, -3 popped) | 5 |
| 5 | 3 | 4:5, 5:3 | 5 |
| 6 | 6 | 6:6 | 6 |
| 7 | 7 | 7:7 | 7 |

## Complexity

- Time: **O(n)**. Each index is pushed once and popped at most once (from either end), so the total work over all iterations is O(n), even though a single step can pop many.
- Space: **O(k)** for the deque.

## Edge cases

- `k == 1`: the output is the input.
- `k == n`: one window, the global max.
- Decreasing input: the deque grows to k and elements leave by expiry.
- Duplicates: handled by `<=`.

## Common mistakes

- Storing values instead of indices (cannot detect expiry).
- Popping from the front for the "smaller" check instead of the back.
- Claiming O(nk) worst case: the amortized argument shows O(n).

## Follow-ups you should be ready for

1. **Sliding window minimum.** Flip the comparison (increasing deque).
2. **Shortest Subarray with Sum at Least K (LeetCode 862).** Monotonic deque over prefix sums; handles negatives.
3. **Constrained Subsequence Sum / Jump Game VI (LeetCode 1425, 1696).** DP where each state needs the max of the previous k states: this deque makes it O(n).

## What to remember

An element that is older and not larger than a newer element can never be a window maximum again. Delete such elements, and what remains is a decreasing deque whose front is the answer. Amortized O(1) per step.
