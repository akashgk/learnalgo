# Same BSTs

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** Recursive structure comparison without building the trees

## The problem

Two arrays each describe a sequence of insertions into an empty BST (duplicates go to the right). **Without building the BSTs**, determine whether the two sequences produce the same tree.

```
arrayOne = [10, 15, 8, 12, 94, 81, 5, 2, 11]
arrayTwo = [10, 8, 5, 15, 2, 12, 11, 94, 81]
->  true

         10
       /    \
      8      15
     /      /  \
    5      12   94
   /      /    /
  2      11   81
```

## Step 1: The easy way (not allowed)

Build both trees by inserting, then compare them recursively. O(n^2) worst case and O(n) space. The restriction is there to test whether you understand **how insertion order determines structure**.

## Step 2: What determines the tree

- The **first** element is the root. So the first elements must be equal.
- Every later element smaller than the root ends up in the **left subtree**; every element greater than or equal ends up in the **right subtree**.
- Crucially, the **relative order** of the smaller elements is exactly the insertion order of the left subtree. The larger elements are interleaved with them, but that does not matter: insertions into the right subtree never affect the left subtree.

So the two trees are the same iff:

1. the arrays have the same length,
2. the first elements are equal,
3. the "smaller than root" subsequences produce the same BST (recursively),
4. the "greater or equal" subsequences produce the same BST (recursively).

## Step 3: Simple recursive version

```
same(a, b):
    if lengths differ or first elements differ: false
    if both empty: true
    return same(smaller(a), smaller(b)) and same(biggerOrEqual(a), biggerOrEqual(b))
```

Building the subsequences at every level costs O(n) per call: **O(n^2) time and O(n^2) space** in total.

## Step 4: Space optimization: indices and bounds

Instead of building new arrays, describe a subtree by:

- the index of its root in each array, and
- the value range `[min, max)` that elements of this subtree must fall into.

The root of the left subtree of a node at index `i` is the **first later index** whose value is smaller than `array[i]` and within the current range. Similarly for the right subtree. No copying: **O(d) space**, where d is the depth.

## Step 5: The code

<!-- CODE:START -->

Full source: [`same_bsts.dart`](same_bsts.dart) (run it with `dart run`).

```dart
// Same BSTs: would inserting arrayOne and arrayTwo (in order) into empty BSTs produce the
// same tree? Compare roots, then recursively compare the "smaller" and ">= root" subsequences
// using index pointers instead of new arrays. O(n^2) time, O(d) space.

bool sameBsts(List<int> arrayOne, List<int> arrayTwo) {
  if (arrayOne.length != arrayTwo.length) return false;
  if (arrayOne.isEmpty) return true;
  return _same(arrayOne, arrayTwo, 0, 0, null, null);
}

/// Compares the subtrees rooted at the first element of each array (at or after rootIdx)
/// whose value lies within [min, max).
bool _same(List<int> a, List<int> b, int? rootA, int? rootB, int? min, int? max) {
  if (rootA == null || rootB == null) return rootA == rootB;
  if (a[rootA] != b[rootB]) return false;
  final value = a[rootA];
  final leftA = _firstSmaller(a, rootA, min), leftB = _firstSmaller(b, rootB, min);
  final rightA = _firstBiggerOrEqual(a, rootA, max), rightB = _firstBiggerOrEqual(b, rootB, max);
  return _same(a, b, leftA, leftB, min, value) && _same(a, b, rightA, rightB, value, max);
}

/// First index after [start] whose value is smaller than a[start] and >= min.
int? _firstSmaller(List<int> a, int start, int? min) {
  for (var i = start + 1; i < a.length; i++) {
    if (a[i] < a[start] && (min == null || a[i] >= min)) return i;
  }
  return null;
}

/// First index after [start] whose value is >= a[start] and < max.
int? _firstBiggerOrEqual(List<int> a, int start, int? max) {
  for (var i = start + 1; i < a.length; i++) {
    if (a[i] >= a[start] && (max == null || a[i] < max)) return i;
  }
  return null;
}
```

<!-- CODE:END -->

### Walkthrough

- `sameBsts` checks lengths and the empty case, then starts with both roots at index 0 and an unbounded range.
- `_same(a, b, rootA, rootB, min, max)`:
  - if either subtree root is missing, both must be missing;
  - the root values must match;
  - find each array's left-subtree root (`_firstSmaller`) and right-subtree root (`_firstBiggerOrEqual`) within the range;
  - recurse with the range narrowed: left gets `[min, value)`, right gets `[value, max)`.
- The helpers scan forward from the current root for the first element that belongs to the requested subtree.

## Step 6: Dry run (top level of the example)

| array | root | first smaller (left root) | first bigger-or-equal (right root) |
|---|---|---|---|
| one | 10 | 8 | 15 |
| two | 10 | 8 | 15 |

Roots match; recurse into left (range < 10) and right (range >= 10) and repeat. In the right subtree both give root 15, left child 12, right child 94, and so on down to the leaves.

## Complexity

| Version | Time | Space |
|---|---|---|
| Build both trees | O(n^2) worst | O(n) |
| Subsequence recursion | O(n^2) | O(n^2) |
| Index + bounds recursion | O(n^2) | O(d) |

## Common mistakes

- Comparing sorted arrays (same values do not mean the same shape).
- Forgetting that duplicates go right (use `>=` for the right subtree).

## What to remember

In a BST built by insertion, the root is first, and the relative order of smaller (and of larger) elements is all that determines each subtree.
