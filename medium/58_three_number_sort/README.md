# Three Number Sort

**Difficulty:** Medium | **Category:** Sorting | **Pattern:** Dutch national flag (3-way partition)

## The problem

You get an array containing only values from a 3-element list `order`, and must sort it **in place** so that all occurrences of `order[0]` come first, then `order[1]`, then `order[2]`. Not every value has to appear.

```
array = [1, 0, 0, -1, -1, 0, 1, 1], order = [0, 1, -1]
->  [0, 0, 0, 1, 1, 1, -1, -1]
```

## Step 1: Counting sort (two passes)

Count how many of each of the three values appear, then overwrite the array: that many `order[0]`, then `order[1]`, then `order[2]`. **O(n) time, O(1) space.** A perfectly good first answer.

## Step 2: One pass: three regions

Edsger Dijkstra's **Dutch national flag** algorithm (the Dutch flag has three stripes) sorts in a single pass using three pointers that divide the array into four regions:

```
[0, lo)      : first value
[lo, mid)    : second value
[mid, hi]    : not examined yet
(hi, end]    : third value
```

Look at `array[mid]`:

- **first value:** swap it with `array[lo]`, then advance both `lo` and `mid`. (The value swapped from `lo` was a second value, already examined, so `mid` can move on.)
- **second value:** already in the right region: advance `mid`.
- **third value:** swap it with `array[hi]` and decrement `hi`. **Do not advance `mid`**: the value that came from `hi` has not been examined yet.

Stop when `mid > hi` (nothing left unexamined).

The "do not advance `mid` after swapping with `hi`" rule is the classic bug. Say it out loud in an interview.

## Step 3: The code

<!-- CODE:START -->

Full source: [`three_number_sort.dart`](three_number_sort.dart) (run it with `dart run`).

```dart
// Three Number Sort: sort `array` so its values follow the order given in `order` (3 values).
// Dutch national flag partition in one pass. O(n) time, O(1) space.

List<int> threeNumberSort(List<int> array, List<int> order) {
  final [first, second, _] = order;
  var lo = 0, mid = 0, hi = array.length - 1;
  // Invariant: [0, lo) first, [lo, mid) second, (hi, end] third, [mid, hi] unknown.
  while (mid <= hi) {
    final v = array[mid];
    if (v == first) {
      _swap(array, lo++, mid++);
    } else if (v == second) {
      mid++;
    } else {
      _swap(array, mid, hi--); // do not advance mid: the swapped-in value is unexamined
    }
  }
  return array;
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}
```

<!-- CODE:END -->

### Walkthrough

- `final [first, second, _] = order;` destructures the order list; the third value is implied (anything else).
- `_swap(array, lo++, mid++)` swaps then advances both (post-increment).
- `_swap(array, mid, hi--)` swaps and shrinks the right region, leaving `mid` in place.

## Step 4: Dry run

`[1, 0, 0, -1, -1, 0, 1, 1]`, first = 0, second = 1, third = -1:

| lo | mid | hi | array[mid] | action | array after |
|---|---|---|---|---|---|
| 0 | 0 | 7 | 1 | second: mid++ | unchanged |
| 0 | 1 | 7 | 0 | first: swap(0, 1) | [0, 1, 0, -1, -1, 0, 1, 1] |
| 1 | 2 | 7 | 0 | first: swap(1, 2) | [0, 0, 1, -1, -1, 0, 1, 1] |
| 2 | 3 | 7 | -1 | third: swap(3, 7) | [0, 0, 1, 1, -1, 0, 1, -1] |
| 2 | 3 | 6 | 1 | second: mid++ | |
| 2 | 4 | 6 | -1 | third: swap(4, 6) | [0, 0, 1, 1, 1, 0, -1, -1] |
| 2 | 4 | 5 | 1 | second: mid++ | |
| 2 | 5 | 5 | 0 | first: swap(2, 5) | [0, 0, 0, 1, 1, 1, -1, -1] |
| 3 | 6 | 5 | | mid > hi: stop | |

## Complexity

- **Time: O(n)**, one pass.
- **Space: O(1)**.

## Common mistakes

- Advancing `mid` after swapping with `hi`.
- Loop condition `mid < hi` instead of `mid <= hi` (misses the last unexamined element).

## Follow-ups

1. **Sort Colors (LeetCode #75):** values 0, 1, 2.
2. **3-way quicksort:** partitioning into `< pivot`, `== pivot`, `> pivot` with this exact scheme makes quicksort fast on arrays with many duplicates.
3. **k distinct values:** counting sort generalizes; the one-pass pointer scheme does not.

## What to remember

Three regions, three pointers. Swapping with the right end brings in an unexamined value, so do not advance the middle pointer then.
