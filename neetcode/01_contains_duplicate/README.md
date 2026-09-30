# Contains Duplicate

**Difficulty:** Easy | **Category:** Arrays & Hashing | **Pattern:** Hash set membership | **Source:** LeetCode 217; NeetCode 150, Blind 75

## The problem

Return true if any value appears at least twice in the array, false if all values are distinct.

```
[1, 2, 3, 1]  ->  true
[1, 2, 3, 4]  ->  false
```

## Step 1: Brute force

Compare every pair: O(n^2) time, O(1) space.

## Step 2: What is the repeated work?

For each element, the inner loop asks "have I seen this value before?". That is a **membership** question, and a hash set answers it in O(1) on average. Walk once, check the set, add to the set.

## Step 3: The trade-off menu

This problem is simple, but it is the cleanest example of the three-way trade-off you will discuss in harder problems:

| Approach | Time | Extra space | Notes |
|---|---|---|---|
| All pairs | O(n^2) | O(1) | |
| Sort, compare neighbors | O(n log n) | O(1) if sorting in place | modifies the input (or O(n) for a copy) |
| Hash set | O(n) | O(n) | stops at the first repeat |

Say all three in an interview, then pick based on the constraint the interviewer cares about.

## Step 4: The code

<!-- CODE:START -->

Full source: [`contains_duplicate.dart`](contains_duplicate.dart) (run it with `dart run`).

```dart
// Contains Duplicate: does any value appear at least twice?
// Hash set, stop at the first repeat. O(n) time, O(n) space.

bool containsDuplicate(List<int> nums) {
  final seen = <int>{};
  for (final x in nums) {
    if (!seen.add(x)) return true; // Set.add returns false when x was already present
  }
  return false;
}

/// Alternative with O(1) extra space if mutation is allowed: sort, then compare neighbors. O(n log n).
bool containsDuplicateBySorting(List<int> nums) {
  final a = [...nums]..sort();
  for (var i = 1; i < a.length; i++) {
    if (a[i] == a[i - 1]) return true;
  }
  return false;
}
```

<!-- CODE:END -->

### Walkthrough

- `seen.add(x)` returns false when `x` was already present, so the check and the insert are one operation.
- The sorted variant copies the input to avoid mutating it; equal values become adjacent after sorting.

## Step 5: Dry run

`[1, 2, 3, 1]`:

| x | seen before | add returns | result |
|---|---|---|---|
| 1 | {} | true | continue |
| 2 | {1} | true | continue |
| 3 | {1, 2} | true | continue |
| 1 | {1, 2, 3} | **false** | return true |

## Complexity

- Hash set: **O(n)** expected time, **O(n)** space.
- Sorting: **O(n log n)** time, O(1) extra with in-place sort.

## Edge cases

- Empty or single-element array: false.
- Negative numbers: no special handling.

## Common mistakes

- Returning after the first comparison inside the loop (for example `return seen.add(x)`).
- Using a list and `contains` (O(n) per lookup: back to O(n^2)).

## Follow-ups you should be ready for

1. **Contains Duplicate II (LeetCode 219).** Duplicate within distance k: a sliding window set of size k.
2. **Contains Duplicate III (LeetCode 220).** Values within t and indices within k: bucket by `value ~/ (t + 1)`.
3. **Huge input that does not fit in memory.** External sort, or partition by hash into files and check each file.

## What to remember

"Have I seen this before?" is a hash set question. Know the sorting alternative for O(1) space.
