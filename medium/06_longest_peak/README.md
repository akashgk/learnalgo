# Longest Peak

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Find anchors, expand outward

## The problem

A **peak** is a run of adjacent integers that is **strictly increasing** up to a tip and then **strictly decreasing**, with at least three elements. Return the length of the longest peak in the array, or 0 if there is none.

```
[1, 4, 10, 2]            is a peak (4 elements)
[4, 0, 10]               is not (goes down first)
[1, 2, 2, 0]             is not (2, 2 is flat)

[1, 2, 3, 3, 4, 0, 10, 6, 5, -1, -3, 2, 3]  ->  6    (0, 10, 6, 5, -1, -3)
```

## Step 1: Work an example by hand

Scanning the example, where are the peaks? Look for elements higher than **both** neighbors:

- `4` at index 4 (3 < 4 > 0),
- `10` at index 6 (0 < 10 > 6).

Every peak has exactly one such **tip**. From each tip, walk left while values keep decreasing (going backward), and walk right while values keep decreasing. For the tip `10`: left stops immediately (4 is not less than 0), right goes 6, 5, -1, -3 and stops at 2. Peak `0, 10, 6, 5, -1, -3`, length 6.

## Step 2: Brute force

For every subarray of length >= 3, check whether it is a peak: O(n^2) subarrays times O(n) check = O(n^3). Or for each index as a potential tip, expand both ways: O(n^2) in the worst case if expansions overlap.

## Step 3: Optimize

1. **Anchors:** tips are easy to detect locally (compare with two neighbors), and each peak has exactly one tip. So only expand from tips.
2. **Skip ahead:** after measuring a peak, jump `i` to the end of its descending slope. Nothing strictly inside a descending slope can be a tip (a tip needs its left neighbor to be smaller, but on a descending slope the left neighbor is bigger). So no work is wasted re-scanning it.

With the skip, every element is visited at most a constant number of times. O(n).

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_peak.dart`](longest_peak.dart) (run it with `dart run`).

```dart
// Longest Peak: strictly increasing then strictly decreasing run, length >= 3.
// Find each peak tip, expand both ways, then jump past it. O(n) time, O(1) space.

int longestPeak(List<int> array) {
  var longest = 0;
  var i = 1;
  while (i < array.length - 1) {
    final isTip = array[i - 1] < array[i] && array[i] > array[i + 1];
    if (!isTip) {
      i++;
      continue;
    }
    var left = i - 1;
    while (left > 0 && array[left - 1] < array[left]) {
      left--;
    }
    var right = i + 1;
    while (right < array.length - 1 && array[right] > array[right + 1]) {
      right++;
    }
    final length = right - left + 1;
    if (length > longest) longest = length;
    i = right; // nothing between the tip and `right` can be a tip
  }
  return longest;
}
```

<!-- CODE:END -->

### Walkthrough

- `var i = 1; while (i < array.length - 1)` only considers positions that have both neighbors.
- `final isTip = array[i - 1] < array[i] && array[i] > array[i + 1];` uses strict comparisons, so flat sections never count.
- The `left` loop walks back while each step going left is strictly lower (`array[left - 1] < array[left]`).
- The `right` loop walks forward while strictly decreasing.
- `final length = right - left + 1;` counts both ends inclusive.
- `i = right;` jumps past the descending slope.

## Step 5: Dry run

`[1, 2, 3, 3, 4, 0, 10, 6, 5, -1, -3, 2, 3]` (indices 0..12):

| i | value | tip? | left, right | length | longest |
|---|---|---|---|---|---|
| 1 | 2 | no (2 < 3) | | | 0 |
| 2 | 3 | no (3 > 3 fails) | | | 0 |
| 3 | 3 | no (3 < 3 fails) | | | 0 |
| 4 | 4 | yes | 3, 5 | 3 | 3 |
| 5 | 0 | no | | | 3 |
| 6 | 10 | yes | 5, 10 | 6 | 6 |
| 10 | -3 | no | | | 6 |
| 11 | 2 | no (2 > 3 fails) | | | 6 |

Answer: 6.

## Complexity

- **Time: O(n)**. The main index only moves forward, and each expansion covers elements that belong to one peak's slopes. An element can be walked by the right expansion of one peak and the left expansion of the next, so each element is touched at most a few times.
- **Space: O(1)**.

## Edge cases

- Fewer than 3 elements: 0.
- Strictly increasing or strictly decreasing array: no tip, 0.
- Plateaus (`1, 2, 2, 1`): no strict tip, 0.

## Common mistakes

- Using `<=` / `>=`, which counts flat sections.
- Forgetting that a peak needs **both** slopes (a strictly increasing array has no peak).
- Starting the left expansion at the tip instead of `tip - 1`, or getting the length off by one.

## Follow-ups

1. **Longest Mountain in Array (LeetCode #845):** identical. A DP alternative: `up[i]` = length of the strictly increasing run ending at i, `down[i]` = length of the strictly decreasing run starting at i; answer `max(up[i] + down[i] + 1)` over i where both are positive.
2. **Count peaks** or **peak index in a mountain array (#852):** the latter uses binary search, because the array is a single mountain.

## What to remember

Find the unique anchor of each pattern (here, the tip), expand from anchors only, and skip regions that cannot contain another anchor.
