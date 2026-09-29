# Permutations

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Backtracking

## The problem

Given an array of **distinct** integers, return all of its permutations, in any order. An empty input returns an empty list.

```
[1, 2, 3]  ->  [[1, 2, 3], [1, 3, 2], [2, 1, 3], [2, 3, 1], [3, 2, 1], [3, 1, 2]]
```

## Step 1: Work an example by hand

To write down all orderings of `1, 2, 3` systematically:

- Choose the first element: 1, 2, or 3 (3 choices).
- For each, choose the second from the remaining two (2 choices).
- The last is forced (1 choice).

`3 * 2 * 1 = 6` permutations. In general n!.

That process is a **decision tree**: each level fixes one position, each branch is one choice. Every leaf is a permutation.

```
                     []
          /          |          \
        [1]         [2]         [3]
       /   \       /   \       /   \
    [1,2] [1,3] [2,1] [2,3] [3,2] [3,1]
      |     |     |     |     |     |
   [1,2,3] ...
```

## Step 2: Backtracking template

Walk the decision tree with recursion:

```
build(position):
    if position == n: record a copy of the current arrangement; return
    for each choice available for this position:
        make the choice
        build(position + 1)
        undo the choice          <- "backtrack"
```

**Choose, explore, un-choose.** This template solves Permutations, Powerset, Phone Number Mnemonics, N-Queens, Sudoku, Generate Parentheses, and many more. Learn it once.

## Step 3: Two ways to "choose"

1. **Used-flags version:** keep a `current` list and a `used` boolean array. For each unused element: mark used, append, recurse, remove, unmark.
2. **Swap version (this code):** the prefix `a[0..i-1]` holds the choices made so far; `a[i..]` holds the remaining elements. To choose element `a[j]` for position i, swap it into position i, recurse on `i + 1`, then swap back. No extra arrays needed.

## Step 4: The code

<!-- CODE:START -->

Full source: [`permutations.dart`](permutations.dart) (run it with `dart run`).

```dart
// Permutations of distinct integers. Backtracking by swapping in place.
// O(n * n!) time (n! permutations, O(n) to copy each), O(n * n!) output space.

List<List<int>> getPermutations(List<int> array) {
  final result = <List<int>>[];
  final a = [...array];

  void permute(int i) {
    if (i == a.length) {
      if (a.isNotEmpty) result.add([...a]);
      return;
    }
    for (var j = i; j < a.length; j++) {
      _swap(a, i, j); // choose a[j] for position i
      permute(i + 1);
      _swap(a, i, j); // undo (backtrack)
    }
  }

  permute(0);
  return result;
}

void _swap(List<int> a, int i, int j) {
  final t = a[i];
  a[i] = a[j];
  a[j] = t;
}
```

<!-- CODE:END -->

### Walkthrough

- `final a = [...array];` works on a copy.
- `permute(i)`: when `i == a.length`, every position is fixed: record a **copy** (`[...a]`). Without copying, every recorded entry would be the same list object, mutated afterward.
- `if (a.isNotEmpty)` makes the empty input return `[]` as the problem requires.
- The loop swaps each remaining element into position `i`, recurses, and swaps back to restore the array for the next choice.

## Step 5: Dry run (first branch)

| call | array | action |
|---|---|---|
| permute(0), j=0 | [1, 2, 3] | swap(0,0), recurse |
| permute(1), j=1 | [1, 2, 3] | swap(1,1), recurse |
| permute(2), j=2 | [1, 2, 3] | recurse to permute(3): record [1, 2, 3] |
| permute(1), j=2 | [1, 3, 2] | swap(1,2), recurse -> record [1, 3, 2]; swap back |
| permute(0), j=1 | [2, 1, 3] | swap(0,1), and so on |

## Complexity

- **Time: O(n * n!)**: there are n! leaves, and copying each permutation costs O(n). (The internal nodes of the tree add up to about e * n! in total, still O(n * n!).)
- **Space: O(n * n!)** for the output; O(n) recursion depth.

This is optimal: the output itself has n! entries of length n.

## Common mistakes

- Recording the array without copying it.
- Forgetting to undo the swap (later branches see a scrambled array).
- Returning `[[]]` for an empty input (this problem wants `[]`; LeetCode wants `[[]]`; check).

## Follow-ups

1. **Permutations II (LeetCode #47), duplicates in the input:** sort first; in the used-flags version, skip `nums[i]` if it equals `nums[i-1]` and `nums[i-1]` is not used in the current path. In the swap version, keep a per-level set of values already tried at this position.
2. **Next Permutation (#31):** generate the next arrangement in lexicographic order in O(n) without recursion.
3. **k-th permutation (#60):** compute it directly with factorial number systems.

## What to remember

Backtracking = choose, explore, un-choose. Copy the state when you record a result.
