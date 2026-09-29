# Move Element To End

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Two pointers / in-place partition

## The problem

Given an array of integers and an integer `toMove`, move every occurrence of `toMove` to the end of the array, **in place**, and return the array. The order of the other elements does not matter.

```
array = [2, 1, 2, 2, 2, 3, 4, 2], toMove = 2
->  [4, 1, 3, 2, 2, 2, 2, 2]   (any order of 4, 1, 3 at the front is fine)
```

### Clarifying questions

- Must the other elements keep their relative order? (Not here. If yes, use the write-pointer version in Follow-ups.)
- In place? (Yes, O(1) extra space.)

## Step 1: Work an example by hand

Think of it as splitting the array into two regions: "not `toMove`" on the left, "`toMove`" on the right. You can build both regions at the same time from both ends:

- From the right, skip over elements that are already `toMove` (they are already where they belong).
- From the left, when you find a `toMove`, swap it with the element at the right pointer (which, after skipping, is guaranteed **not** to be `toMove`).

## Step 2: Brute force ideas

- Build a new array: non-`toMove` values first, then the `toMove` values. O(n) time but O(n) extra space (violates "in place").
- Sort: does not work in general (sorting orders by value, not by "is it `toMove`"), and it is O(n log n).

## Step 3: Two pointers

```
i = 0, j = n - 1
while i < j:
    while i < j and array[j] == toMove: j--      # right region is already correct
    if array[i] == toMove: swap array[i], array[j]
    i++
```

**Invariant:** everything left of `i` is not `toMove`; everything right of `j` is `toMove`. Each iteration grows at least one of those regions, so the loop ends in O(n).

This is the same idea as the **partition** step of quicksort, with "equals `toMove`" as the pivot test.

## Step 4: The code

<!-- CODE:START -->

Full source: [`move_element_to_end.dart`](move_element_to_end.dart) (run it with `dart run`).

```dart
// Move Element To End (in place, order of others not required).
// Two pointers: right pointer skips values already equal to toMove; swap on the left.
// O(n) time, O(1) space.

List<int> moveElementToEnd(List<int> array, int toMove) {
  var i = 0, j = array.length - 1;
  while (i < j) {
    while (i < j && array[j] == toMove) {
      j--;
    }
    if (array[i] == toMove) {
      array[i] = array[j];
      array[j] = toMove;
    }
    i++;
  }
  return array;
}
```

<!-- CODE:END -->

### Walkthrough

- `var i = 0, j = array.length - 1;` are the two ends.
- The inner `while` moves `j` left past values that are already `toMove`.
- `if (array[i] == toMove)`: write `array[j]` into `i` and `toMove` into `j`. Because we know the value at `i` is `toMove`, we can write the constant instead of doing a full swap.
- `i++` always advances: after this step `array[i]` is definitely not `toMove`.

## Step 5: Dry run

`[2, 1, 2, 2, 2, 3, 4, 2]`, toMove 2:

| i | j after skipping | array[i] | action | array after |
|---|---|---|---|---|
| 0 | 6 (value 4) | 2 | swap with j | [4, 1, 2, 2, 2, 3, 2, 2] |
| 1 | 5 (value 3) | 1 | none | unchanged |
| 2 | 5 (value 3) | 2 | swap with j | [4, 1, 3, 2, 2, 2, 2, 2] |
| 3 | 3 (skipped indices 5 and 4) | 2 | self-swap at i == j (harmless) | unchanged; `i` becomes 4 and the loop ends |

## Complexity

- **Time: O(n)**. Each iteration moves `i` right or `j` left; together they travel at most n steps.
- **Space: O(1)**.

## Edge cases

- Empty array, or no occurrences: unchanged.
- All elements equal `toMove`: `j` walks to `i` immediately; nothing moves.

## Common mistakes

- Forgetting the `i < j` check inside the inner loop (`j` can run past `i`, or below 0).
- Swapping `array[i]` with `array[j]` when `array[j]` is itself `toMove`.

## Follow-ups

1. **Keep relative order (LeetCode #283, Move Zeroes):** a write pointer `w`. For each element that is not `toMove`, write it at `w` and increment `w`. Then fill positions `w..end` with `toMove`. O(n) time, O(1) space, and stable. Interviewers often ask for exactly this variant.
2. **Three categories:** see Three Number Sort (medium 58), the Dutch national flag problem.
3. **Remove Element (LeetCode #27):** same partitioning; return the length of the kept prefix.

## What to remember

Two-way in-place partition: one pointer from each end, skip elements already in their correct region, swap the rest.
