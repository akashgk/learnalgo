# Next Permutation

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Pivot + suffix reversal | **Source:** LeetCode 31; Striver A2Z

## The problem

Rearrange an array of integers **in place** into the next permutation in lexicographic (dictionary) order. If it is already the largest permutation, wrap around to the smallest (sorted ascending). Use O(1) extra memory.

```
[1, 2, 3]          ->  [1, 3, 2]
[3, 2, 1]          ->  [1, 2, 3]      (last permutation wraps)
[1, 1, 5]          ->  [1, 5, 1]
[2, 3, 6, 5, 4, 1] ->  [2, 4, 1, 3, 5, 6]
```

### Clarifying questions to ask

| Question | Why it matters |
|---|---|
| Can values repeat? | Yes. The comparisons must be written carefully (`>=` vs `>`) or duplicates break it. |
| In place? | Yes, O(1) extra space. Generating all permutations is not acceptable. |
| What if it is the last permutation? | Return the first one (sorted ascending). |

## Step 1: Work an example by hand

Think of permutations as numbers: `2 3 6 5 4 1` is like the number 236541. The next permutation is the **smallest number bigger than it** that uses the same digits.

To make the number bigger by the **least** amount, change it as far to the **right** as possible. Changing a left digit makes a big jump; changing a right digit makes a small one.

Look at the suffix `6 5 4 1`. It is **non-increasing**: it is already the largest arrangement of those four digits. No rearrangement of just that suffix can make the number bigger. So we are forced to change the digit just before it: the `3`. That digit is the **pivot**: the rightmost position `i` with `a[i] < a[i+1]`.

What should replace the 3? Something from the suffix that is **bigger than 3**, and as small as possible: that is 4. Swap them: `2 4 6 5 3 1`.

Now the prefix `2 4` is already bigger than before, so the suffix should be as **small** as possible: sorted ascending, `1 3 5 6`. Result: `2 4 1 3 5 6`.

## Step 2: Brute force

Generate all permutations, sort them, find the current one, return the next. O(n! * n) time and space. Only worth saying to show you know why it is unacceptable.

## Step 3: Optimize to O(n), O(1)

The hand analysis already is the algorithm. Three steps:

1. **Find the pivot:** scan from the right for the first `i` with `a[i] < a[i+1]`. If there is none, the whole array is non-increasing (the last permutation): skip to step 3 with `i = -1`, which reverses everything.
2. **Find the successor:** scan from the right for the first `j` with `a[j] > a[i]`. Because the suffix is non-increasing, the rightmost value greater than `a[i]` is also the **smallest** value greater than `a[i]`. Swap `a[i]` and `a[j]`.
3. **Sort the suffix cheaply:** after the swap, the suffix is **still non-increasing**. (Proof: `a[j]` was the rightmost value greater than `a[i]`, so everything right of `j` is `<= a[i]`, and everything left of `j` in the suffix is `>= a[j] > a[i]`. Putting `a[i]` at position `j` keeps the order.) A non-increasing sequence is sorted ascending by **reversing** it: O(n) instead of O(n log n).

## Step 4: The code

<!-- CODE:START -->

Full source: [`next_permutation.dart`](next_permutation.dart) (run it with `dart run`).

```dart
// Next Permutation: rearrange into the next lexicographically greater order, in place.
// If none exists (fully descending), wrap to the smallest order. O(n) time, O(1) space.

void nextPermutation(List<int> a) {
  final n = a.length;
  // 1. Find the pivot: the rightmost i with a[i] < a[i + 1]. Everything after it is non-increasing.
  var i = n - 2;
  while (i >= 0 && a[i] >= a[i + 1]) {
    i--;
  }
  if (i >= 0) {
    // 2. Swap the pivot with the rightmost element that is strictly greater than it.
    var j = n - 1;
    while (a[j] <= a[i]) {
      j--;
    }
    _swap(a, i, j);
  }
  // 3. The suffix is still non-increasing; reverse it to make it the smallest possible.
  _reverse(a, i + 1, n - 1);
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}

void _reverse(List<int> a, int lo, int hi) {
  while (lo < hi) {
    _swap(a, lo++, hi--);
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `while (i >= 0 && a[i] >= a[i + 1]) i--;` uses `>=`, not `>`. With duplicates like `[1, 5, 1]`, equal neighbors are part of the non-increasing suffix.
- `while (a[j] <= a[i]) j--;` uses `<=`: we need a **strictly** greater value, or swapping equal values changes nothing.
- `_reverse(a, i + 1, n - 1)` runs in both cases. When `i == -1`, it reverses the whole array, turning the last permutation into the first.

## Step 5: Dry run

`[2, 3, 6, 5, 4, 1]`:

| Step | State | Note |
|---|---|---|
| find pivot | i = 1 (value 3) | from the right: 4 >= 1, 5 >= 4, 6 >= 5 continue; 3 < 6 stops |
| find successor | j = 4 (value 4) | from the right: 1 <= 3 skip, 4 > 3 stop |
| swap | `[2, 4, 6, 5, 3, 1]` | suffix `6 5 3 1` still non-increasing |
| reverse suffix | `[2, 4, 1, 3, 5, 6]` | smallest arrangement of the suffix |

## Complexity

- Time: **O(n)**. Each of the three scans is at most one pass.
- Space: **O(1)**. Only indices and one temporary for swaps.

## Edge cases

| Input | Expected | Handled by |
|---|---|---|
| `[3, 2, 1]` | `[1, 2, 3]` | no pivot, `i = -1`, reverse everything |
| `[7]` | `[7]` | no pivot, reversing one element is a no-op |
| `[1, 5, 1]` | `[5, 1, 1]` | `>=` and `<=` comparisons handle duplicates |

## Common mistakes

- Using `>` in the pivot scan: with `[1, 1]` you would pick a pivot between equal values and produce the same array.
- Sorting the suffix: correct, but O(n log n). Say why reversing is enough.
- Swapping the pivot with the **smallest value in the suffix** instead of the smallest value **greater than the pivot**.

## Follow-ups you should be ready for

1. **Previous permutation.** Mirror every comparison: pivot is the rightmost `a[i] > a[i+1]`, successor is the rightmost value smaller than the pivot.
2. **k-th permutation directly.** See more_problems 28 Permutation Sequence (factorial number system).
3. **Next greater number with the same digits (LeetCode 556).** Same algorithm on the digits, plus an overflow check.
4. **Generate all permutations in order.** Start sorted and call next permutation n! - 1 times. This is how C++ `std::next_permutation` loops work, and it handles duplicates without a set.

## What to remember

Change as far right as possible. The longest non-increasing suffix cannot grow; the element before it (the pivot) must increase by the minimum amount, and then the suffix must become as small as possible, which is a reversal.
