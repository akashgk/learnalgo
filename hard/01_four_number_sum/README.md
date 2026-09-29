# Four Number Sum

**Difficulty:** Hard | **Category:** Arrays | **Pattern:** Pair sums in a hash map (meet in the middle)

## The problem

Given an array of **distinct** integers and a target sum, return all quadruplets (in any order) of distinct elements whose values sum to the target. No quadruplet may appear twice.

```
array = [7, 6, 4, -1, 1, 2], target = 16
->  [[7, 6, 4, -1], [7, 6, 1, 2]]
```

## Step 1: Build on what you know

- Two Number Sum: hash set, O(n).
- Three Number Sum: sort, fix one number, two pointers: O(n^2).

Extending that to four numbers: sort, fix **two** numbers with two nested loops, two-pointer the rest: **O(n^3)** time, O(1) extra space. That is a solid answer and the one LeetCode #18 expects (it allows duplicates). Can we do better on average?

## Step 2: Meet in the middle

A quadruplet is **two pairs**. If we stored every pair sum in a hash map `sum -> list of pairs`, then for any other pair with sum `s` we could look up the pairs with sum `target - s` in O(1). There are O(n^2) pairs, so this suggests O(n^2).

The hard part is not the idea; it is **avoiding two problems**:

1. **Reusing an element:** the pair `(7, 6)` looked up for the pair `(7, 4)` would use 7 twice.
2. **Duplicates:** the quadruplet `{7, 6, 4, -1}` could be found as `(7,6)+(4,-1)`, `(4,-1)+(7,6)`, `(7,4)+(6,-1)`, and so on.

## Step 3: The split-point trick

Iterate a **split index** `i` from left to right. At each `i`:

1. **Look up first:** for each `j > i`, consider the pair `(array[i], array[j])` as the **second half** of a quadruplet. Look up `target - array[i] - array[j]` among pairs already registered. Every registered pair uses only indices **before** `i`.
2. **Register after:** add every pair `(array[k], array[i])` with `k < i` to the map.

Why this works: take any quadruplet with sorted indices `p < q < r < s`. Its pair `(p, q)` gets registered when the loop is at `i = q`. It is found when the loop is at `i = r` (looking up with the second-half pair `(r, s)`). At that point `(p, q)` is in the map, since `q < r`. Could it be found twice? Only if another split point also sees both halves, but the second half must start at the split index and the first half must end before it. For a fixed quadruplet there is exactly one such split: `i = r`. And elements are never reused, because registered pairs only contain indices smaller than `i`, while second-half pairs contain `i` and larger indices.

## Step 4: The code

<!-- CODE:START -->

Full source: [`four_number_sum.dart`](four_number_sum.dart) (run it with `dart run`).

```dart
// Four Number Sum: all quadruplets of distinct integers summing to target.
// Pair-sum hash map, adding pairs only AFTER using index i as the split point so each
// quadruplet is generated once. Average O(n^2) time (worst O(n^3)), O(n^2) space.

List<List<int>> fourNumberSum(List<int> array, int targetSum) {
  final pairsBySum = <int, List<(int, int)>>{};
  final quadruplets = <List<int>>[];
  for (var i = 1; i < array.length - 1; i++) {
    // Pairs (i, j) with j > i are the "second half"; look up earlier pairs as the first half.
    for (var j = i + 1; j < array.length; j++) {
      final need = targetSum - array[i] - array[j];
      for (final (a, b) in pairsBySum[need] ?? const <(int, int)>[]) {
        quadruplets.add([a, b, array[i], array[j]]);
      }
    }
    // Now register pairs (k, i) with k < i, so they are only seen by later split points.
    for (var k = 0; k < i; k++) {
      (pairsBySum[array[k] + array[i]] ??= []).add((array[k], array[i]));
    }
  }
  return quadruplets;
}

/// Sort + two pointers alternative: O(n^3) time, O(1) extra space, sorted output.
List<List<int>> fourNumberSumSorted(List<int> array, int target) {
  final a = [...array]..sort();
  final out = <List<int>>[];
  for (var i = 0; i < a.length - 3; i++) {
    for (var j = i + 1; j < a.length - 2; j++) {
      var lo = j + 1, hi = a.length - 1;
      while (lo < hi) {
        final s = a[i] + a[j] + a[lo] + a[hi];
        if (s == target) {
          out.add([a[i], a[j], a[lo++], a[hi--]]);
        } else if (s < target) {
          lo++;
        } else {
          hi--;
        }
      }
    }
  }
  return out;
}
```

<!-- CODE:END -->

### Walkthrough of `fourNumberSum`

- `pairsBySum` maps a sum to the list of pairs (as value records) that produce it.
- The outer loop is the split index `i` (starting at 1: a first-half pair needs an index before `i`).
- The first inner loop looks up complements for second-half pairs `(i, j)`.
- The second inner loop registers first-half pairs `(k, i)`.

### Walkthrough of `fourNumberSumSorted`

The O(n^3) alternative: sort, fix `i` and `j`, and run the two-pointer walk on the rest (as in Three Number Sum).

## Step 5: Dry run (hash version)

`[7, 6, 4, -1, 1, 2]`, target 16:

| i | lookups (pair, need) | found | registered pairs (sum) |
|---|---|---|---|
| 1 (6) | (6,4) need 6; (6,-1) need 11; (6,1) need 9; (6,2) need 8 | none | (7,6)=13 |
| 2 (4) | (4,-1) need **13**; (4,1) need 11; (4,2) need 10 | [7, 6, 4, -1] | (7,4)=11, (6,4)=10 |
| 3 (-1) | (-1,1) need 16; (-1,2) need 15 | none | (7,-1)=6, (6,-1)=5, (4,-1)=3 |
| 4 (1) | (1,2) need **13** | [7, 6, 1, 2] | (7,1)=8, (6,1)=7, (4,1)=5, (-1,1)=0 |

Result: `[[7, 6, 4, -1], [7, 6, 1, 2]]`.

## Complexity

| Approach | Time | Space |
|---|---|---|
| Brute force | O(n^4) | O(1) |
| Sort + two pointers | O(n^3) | O(1) extra |
| Pair hash map | O(n^2) average; O(n^3) worst | O(n^2) |

The worst case of the hash version happens when many pairs share the same sum (the lookup lists get long). Mention it: "O(n^2) average, O(n^3) worst".

## Common mistakes

- Registering pairs before doing the lookups at the same split index (allows reusing element `i`).
- Returning duplicate quadruplets.

## Follow-ups

1. **4Sum (LeetCode #18):** duplicates allowed; use the sort + two pointers version with duplicate skipping at every level.
2. **4Sum II (#454):** four separate arrays, count the tuples. Pure meet in the middle: count all sums of A+B in a map, then look up `-(c + d)` for all C+D pairs: O(n^2).
3. **k-Sum:** recursively reduce to 2-sum; or split into two halves and meet in the middle for O(n^(k/2)).

## What to remember

Meet in the middle: split the combination into two halves, store one half in a hash map, look up the other. A split index that orders "store" and "look up" prevents reuse and duplicates.
