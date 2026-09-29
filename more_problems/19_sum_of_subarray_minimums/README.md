# Sum of Subarray Minimums

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Contribution technique + monotonic stack (previous/next smaller) | **Source:** LeetCode 907; Striver A2Z

## The problem

Return the sum of `min(sub)` over **every** contiguous subarray. LeetCode asks for the result modulo 10^9 + 7.

```
[3, 1, 2, 4]  ->  17
```

The subarrays and their minimums: `[3]=3, [1]=1, [2]=2, [4]=4, [3,1]=1, [1,2]=1, [2,4]=2, [3,1,2]=1, [1,2,4]=1, [3,1,2,4]=1`. Sum: 17.

## Step 1: Brute force

For each start, extend the end and keep a running minimum: O(n^2). With n up to 3 * 10^4 it passes in some languages but it is not what the interviewer wants.

## Step 2: Flip the sum: count contributions

Instead of "for each subarray, find its minimum", ask **"for each element, in how many subarrays is it the minimum?"**

```
answer = sum over i of  arr[i] * (number of subarrays where arr[i] is the minimum)
```

This is the **contribution technique**, and it turns many "sum over all subarrays" problems from O(n^2) into O(n).

`arr[i]` is the minimum of a subarray `[l, r]` (containing i) exactly when no element in `[l, r]` is smaller. So the subarray can stretch left until just after the **previous smaller element**, and right until just before the **next smaller element**. If there are `left[i]` choices for `l` and `right[i]` choices for `r`, the count is `left[i] * right[i]`.

For `[3, 1, 2, 4]`, element `1` at index 1: no smaller element on either side, so `l` can be 0 or 1 (2 choices) and `r` can be 1, 2 or 3 (3 choices): 6 subarrays, contributing `1 * 6 = 6`.

## Step 3: Ties (the subtle part)

With duplicates, `[2, 2]` has subarray `[2, 2]` whose minimum appears twice. If both copies count it, it is double counted. Fix: make the boundaries **asymmetric**:

- left side stops at a **strictly smaller** element (equal elements are passed over),
- right side stops at a **smaller or equal** element.

Then a subarray whose minimum value occurs several times is attributed to exactly one copy: the **rightmost** one. (The rightmost copy extends left over the others; every other copy's right span is cut off by the next equal copy.)

Check `[2, 2]`: index 0 has left = 1, right = 1 (stops at the equal 2): 1 subarray. Index 1 has left = 2, right = 1: 2 subarrays. Total `2 * (1 + 2) = 6` = `[2] + [2] + [2, 2]`. Correct.

## Step 4: Previous/next smaller with a monotonic stack

"Previous smaller element for every index" is the classic monotonic stack problem. Scan left to right with a stack of indices whose values are increasing. For each `i`, pop while the top is `>= arr[i]`; whatever remains on top is the previous strictly smaller element. Same scan from the right (popping while `> arr[i]`) gives the next smaller-or-equal element.

## Step 5: The code

<!-- CODE:START -->

Full source: [`sum_of_subarray_minimums.dart`](sum_of_subarray_minimums.dart) (run it with `dart run`).

```dart
// Sum of Subarray Minimums: sum of min(sub) over every contiguous subarray (LeetCode returns it mod 1e9+7).
// Contribution technique: arr[i] is the minimum of left[i] * right[i] subarrays, where the
// spans come from the previous smaller and next smaller-or-equal elements (monotonic stack).
// O(n) time, O(n) space.

const mod = 1000000007;

int sumSubarrayMins(List<int> arr) {
  final n = arr.length;
  final left = List<int>.filled(n, 0); // choices for the left end: i - previous strictly smaller index
  final right = List<int>.filled(n, 0); // choices for the right end: next smaller-or-equal index - i
  final stack = <int>[];
  for (var i = 0; i < n; i++) {
    while (stack.isNotEmpty && arr[stack.last] >= arr[i]) {
      stack.removeLast();
    }
    left[i] = stack.isEmpty ? i + 1 : i - stack.last;
    stack.add(i);
  }
  stack.clear();
  for (var i = n - 1; i >= 0; i--) {
    while (stack.isNotEmpty && arr[stack.last] > arr[i]) {
      stack.removeLast();
    }
    right[i] = stack.isEmpty ? n - i : stack.last - i;
    stack.add(i);
  }
  // Ties: left spans stop at a strictly smaller value, right spans at a smaller-or-equal one,
  // so a subarray whose minimum occurs several times is counted once, by its rightmost copy.
  var total = 0;
  for (var i = 0; i < n; i++) {
    total = (total + arr[i] * left[i] * right[i]) % mod;
  }
  return total;
}
```

<!-- CODE:END -->

### Walkthrough

- First loop: `left[i] = i - (previous strictly smaller index)`, or `i + 1` if none.
- Second loop, right to left: `right[i] = (next smaller-or-equal index) - i`, or `n - i` if none.
- The pop conditions `>=` and `>` implement the tie rule. Swapping them (strict on the right) also works; using the same one on both sides does not.
- Each product is taken modulo 10^9 + 7. In Dart, `arr[i] * left[i] * right[i]` fits in 64 bits for LeetCode's limits (3 * 10^4 * 3 * 10^4 * 3 * 10^4 is below 2^63).

## Step 6: Dry run

`[3, 1, 2, 4]`:

| i | arr[i] | previous strictly smaller | left[i] | next smaller or equal | right[i] | contribution |
|---|---|---|---|---|---|---|
| 0 | 3 | none | 1 | index 1 | 1 | 3 * 1 * 1 = 3 |
| 1 | 1 | none | 2 | none | 3 | 1 * 2 * 3 = 6 |
| 2 | 2 | index 1 | 1 | none | 2 | 2 * 1 * 2 = 4 |
| 3 | 4 | index 2 | 1 | none | 1 | 4 * 1 * 1 = 4 |

Total: 3 + 6 + 4 + 4 = **17**.

## Complexity

- Time: **O(n)**. Each index is pushed and popped at most once per scan.
- Space: **O(n)** for the arrays and stack.

## Edge cases

- Single element: `arr[0]`.
- All equal: the tie rule prevents double counting (test `[2, 2]` -> 6).
- Strictly increasing: each element's right span reaches the end.

## Common mistakes

- Symmetric tie handling (double counting).
- Forgetting the `i + 1` / `n - i` defaults when there is no smaller element.
- Applying the modulo only at the end in a language with 32-bit ints.

## Follow-ups you should be ready for

1. **Sum of Subarray Ranges (LeetCode 2104).** Sum of (max - min) = (sum of subarray maxima) - (sum of subarray minima). Maxima use the same method with "greater" instead of "smaller".
2. **Largest Rectangle in Histogram.** The same previous/next smaller boundaries; see more_problems 21.
3. **Number of subarrays where arr[i] is the maximum.** Same counting.

## What to remember

"Sum of f over all subarrays" often becomes "sum over elements of (value times number of subarrays where it decides f)". Previous/next smaller elements give those counts in O(n); break ties asymmetrically.
