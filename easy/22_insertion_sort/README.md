# Insertion Sort

**Difficulty:** Easy | **Category:** Sorting | **Pattern:** Sorted prefix + insertion

## The problem

Sort an array of integers in ascending order using Insertion Sort, and return it.

```
[8, 5, 2, 9, 5, 6, 3]  ->  [2, 3, 5, 5, 6, 8, 9]
```

## Step 1: The idea

This is how most people sort a hand of playing cards. Keep the cards you have already sorted on the left. Pick up the next card and slide it left past every bigger card until it sits in the right spot. Repeat.

**Invariant:** before processing index `i`, the prefix `array[0..i-1]` is sorted.

## Step 2: Work an example by hand

| i | current | sorted prefix before | shifts | prefix after |
|---|---|---|---|---|
| 1 | 5 | [8] | 8 moves right | [5, 8] |
| 2 | 2 | [5, 8] | 8, 5 move right | [2, 5, 8] |
| 3 | 9 | [2, 5, 8] | none | [2, 5, 8, 9] |
| 4 | 5 | [2, 5, 8, 9] | 9, 8 move right | [2, 5, 5, 8, 9] |
| 5 | 6 | [2, 5, 5, 8, 9] | 9, 8 move right | [2, 5, 5, 6, 8, 9] |
| 6 | 3 | [2, 5, 5, 6, 8, 9] | 9, 8, 6, 5, 5 move right | [2, 3, 5, 5, 6, 8, 9] |

## Step 3: Shift, do not swap

A naive version swaps the new element leftward one position at a time (three writes per step). Better: save the element in `current`, shift each bigger element one position to the right (one write each), and drop `current` into the gap at the end.

## Step 4: The code

<!-- CODE:START -->

Full source: [`insertion_sort.dart`](insertion_sort.dart) (run it with `dart run`).

```dart
// Insertion Sort (in place). Grow a sorted prefix; insert each new element by shifting it left.
// O(n^2) worst/avg, O(n) best, O(1) space. Stable. Great for small or nearly sorted input.

List<int> insertionSort(List<int> array) {
  for (var i = 1; i < array.length; i++) {
    final current = array[i];
    var j = i - 1;
    while (j >= 0 && array[j] > current) {
      array[j + 1] = array[j]; // shift right instead of swapping: fewer writes
      j--;
    }
    array[j + 1] = current;
  }
  return array;
}
```

<!-- CODE:END -->

### Walkthrough

- `for (var i = 1; ...)`: a single element (index 0) is already a sorted prefix.
- `final current = array[i];` saves the element; its slot may be overwritten by shifting.
- `while (j >= 0 && array[j] > current)` shifts bigger elements right. Strict `>` stops at equal elements, so equal values keep their order (stable).
- `array[j + 1] = current;` fills the gap left by the last shift.

## Complexity

| Case | Time | Why |
|---|---|---|
| Best (sorted) | O(n) | the inner loop never runs |
| Average / worst | O(n^2) | up to i shifts for element i |

More precisely, Insertion Sort runs in **O(n + I)** where I is the number of **inversions** (pairs that are out of order). Nearly sorted input has few inversions, so Insertion Sort is excellent there.

- **Space: O(1)**. **Stable:** yes.

## Why it matters in practice

- Real library sorts switch to Insertion Sort for small subarrays (roughly under 16 to 32 elements): TimSort (Python, Java objects), introsort variants in C++, and Dart's own `List.sort` for short ranges. Low overhead beats better asymptotics at tiny sizes.
- It is **online**: it can sort elements as they arrive.
- The inversion count connection links to Count Inversions (very hard 34) and Sort K-Sorted Array (hard 33): if every element is at most k away from its place, Insertion Sort is O(n * k).

## Common mistakes

- Starting the outer loop at 0 (harmless but pointless) or the inner comparison with `>=` (breaks stability).
- Writing `current` into `array[j]` instead of `array[j + 1]`.

## What to remember

Grow a sorted prefix and slide each new element into place. O(n^2) worst case, but O(n + inversions): fast on nearly sorted data, which is why real sorts use it for small ranges.
