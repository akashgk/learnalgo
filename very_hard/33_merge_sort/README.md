# Merge Sort

**Difficulty:** Very Hard (on AlgoExpert, because of the space-efficient version) | **Category:** Sorting | **Pattern:** Divide and conquer

## The problem

Sort an array of integers in ascending order using Merge Sort.

```
[8, 5, 2, 9, 5, 6, 3]  ->  [2, 3, 5, 5, 6, 8, 9]
```

## Step 1: The idea

1. **Divide:** split the array into two halves.
2. **Conquer:** sort each half recursively.
3. **Combine:** merge the two sorted halves into one sorted range, using two pointers: repeatedly take the smaller front element (the same merge as Merge Linked Lists, hard 37).

A single element is already sorted: that is the base case.

```
[8, 5, 2, 9, 5, 6, 3]
[8, 5, 2]          [9, 5, 6, 3]
[8] [5, 2]         [9, 5] [6, 3]
[8] [5] [2]        [9] [5] [6] [3]
merge upward:
[8] [2, 5]         [5, 9] [3, 6]
[2, 5, 8]          [3, 5, 6, 9]
[2, 3, 5, 5, 6, 8, 9]
```

## Step 2: Why O(n log n)?

The recursion has log2(n) levels (the size halves each time). At every level, the merges together touch each element once: O(n) per level. Total: **O(n log n)**, in the best, average, and worst case. There are no bad inputs.

## Step 3: Memory: the naive version and the better one

**Naive:** create new sub-arrays at every split and a new merged array at every merge. It works, but allocates O(n log n) memory over the whole run (O(n) at any single moment).

**Single auxiliary buffer (this code):** allocate one copy of the array at the start. At each level, the recursive calls sort the halves **into the other buffer**, and the current call merges from that buffer into its target. Swapping the roles of `main` and `aux` at every level means no copying back and forth. Total extra memory: one array, O(n).

## Step 4: Stability

When the two front elements are **equal**, take the one from the **left** half (`<=` in the comparison). Equal elements then keep their original order, so merge sort is **stable**. That matters when sorting records by one key after another.

## Step 5: The code

<!-- CODE:START -->

Full source: [`merge_sort.dart`](merge_sort.dart) (run it with `dart run`).

```dart
// Merge Sort with a single auxiliary buffer, alternating roles between levels to avoid copies.
// O(n log n) time in all cases, O(n) space. Stable.

List<int> mergeSort(List<int> array) {
  if (array.length <= 1) return array;
  final aux = [...array];
  _sort(array, 0, array.length - 1, aux);
  return array;
}

/// Sorts main[start..end] using aux (which holds the same values) as the source.
void _sort(List<int> main, int start, int end, List<int> aux) {
  if (start == end) return;
  final mid = (start + end) ~/ 2;
  _sort(aux, start, mid, main); // swap roles: sort halves into aux
  _sort(aux, mid + 1, end, main);
  var i = start, j = mid + 1, k = start;
  while (i <= mid && j <= end) {
    main[k++] = aux[i] <= aux[j] ? aux[i++] : aux[j++]; // <= keeps it stable
  }
  while (i <= mid) {
    main[k++] = aux[i++];
  }
  while (j <= end) {
    main[k++] = aux[j++];
  }
}
```

<!-- CODE:END -->

### Walkthrough

- `mergeSort` creates `aux` as a copy and starts the recursion.
- `_sort(main, start, end, aux)` sorts `main[start..end]`, using `aux` (which holds the same values) as the source for merging:
  - it first sorts both halves **into `aux`** by calling itself with the roles swapped;
  - then merges `aux[start..mid]` and `aux[mid+1..end]` into `main[start..end]`.
- The three `while` loops are the standard merge: while both halves have elements, then the leftovers of each.

## Complexity

- **Time: O(n log n)** in every case.
- **Space: O(n)** for the auxiliary array, plus O(log n) recursion.
- **Stable.** Not in place (in-place merging exists but is complicated and slower).

## When merge sort is the right choice

- You need **stability** (Java sorts objects with a merge-sort variant; Python's TimSort is merge-based).
- **Linked lists:** merging needs no random access and only O(1) extra space for pointers; merge sort is the standard way to sort a linked list (LeetCode #148).
- **External sorting:** data larger than memory is sorted in chunks and then merged (k-way merge, very hard 23).
- **Counting problems** during merging: Count Inversions (very hard 34), Right Smaller Than (very hard 06).

## Common mistakes

- Using `<` in the merge (loses stability).
- Off-by-one in the half boundaries (`mid` belongs to the left half here).

## What to remember

Split, sort both halves, merge with two pointers. O(n log n) always, stable, O(n) extra space; one auxiliary buffer with alternating roles avoids repeated allocation.
