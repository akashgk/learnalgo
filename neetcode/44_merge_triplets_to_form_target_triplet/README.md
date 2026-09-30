# Merge Triplets to Form Target Triplet

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Filter what can never be used, then merge everything else | **Source:** LeetCode 1899; NeetCode 150

## The problem

A merge of two triplets takes the element-wise maximum: `merge([a,b,c], [x,y,z]) = [max(a,x), max(b,y), max(c,z)]`. Can some set of the given triplets be merged into exactly `target`?

```
triplets = [[2,5,3], [1,8,4], [1,7,5]], target = [2,7,5]  ->  true   ([2,5,3] + [1,7,5])
triplets = [[3,4,5], [4,5,6]], target = [3,2,5]           ->  false  (every second value is too big)
```

## Step 1: Merging only grows values

`max` never decreases any coordinate. So a triplet with **any** coordinate larger than the target's can never be part of the answer: using it would make that coordinate too large forever.

## Step 2: The rest are always safe

Every other triplet has all coordinates `<=` target. Merging **all** of them can only bring each coordinate closer to (but never above) the target. So:

- throw away triplets that exceed the target anywhere;
- the answer is true exactly when, for each coordinate, some remaining triplet **equals** the target there.

If coordinate k is never hit exactly by a safe triplet, no subset can produce it (the merged value would stay below the target).

## Step 3: The code

<!-- CODE:START -->

Full source: [`merge_triplets_to_form_target_triplet.dart`](merge_triplets_to_form_target_triplet.dart) (run it with `dart run`).

```dart
// Merge Triplets to Form Target Triplet: merging two triplets takes the element-wise maximum.
// Can some set of the given triplets merge into exactly target?
// A triplet with any value above target can never be used (max only grows). Among the usable ones,
// merge all of them and check whether each coordinate hits its target. O(n) time, O(1) space.

bool mergeTriplets(List<List<int>> triplets, List<int> target) {
  final hit = [false, false, false];
  for (final t in triplets) {
    if (t[0] > target[0] || t[1] > target[1] || t[2] > target[2]) continue; // would overshoot
    for (var k = 0; k < 3; k++) {
      if (t[k] == target[k]) hit[k] = true;
    }
  }
  return hit[0] && hit[1] && hit[2];
}
```

<!-- CODE:END -->

### Walkthrough

- `hit[k]` records whether some safe triplet matches the target in coordinate k.
- There is no need to actually merge; the flags are enough.

## Step 4: Dry run

target `[2, 7, 5]`:

| triplet | safe? | hits |
|---|---|---|
| [2, 5, 3] | yes | coordinate 0 (2) |
| [1, 8, 4] | no (8 > 7) | |
| [1, 7, 5] | yes | coordinates 1 (7) and 2 (5) |

All three hit: **true**.

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- No triplets: false.
- A triplet equal to the target: true on its own.

## Common mistakes

- Trying subsets (exponential).
- Forgetting to discard overshooting triplets before recording hits.

## Follow-ups you should be ready for

1. **Return the triplets used.** Collect the safe triplets that hit at least one coordinate.
2. **Merge with `min`.** Symmetric: discard triplets below the target anywhere.
3. **k-dimensional tuples.** Same reasoning, O(n * k).

## What to remember

When an operation is monotone (here, max), anything that already overshoots is useless, and everything else can be included without harm.
