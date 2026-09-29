# Find Three Largest Numbers

**Difficulty:** Easy | **Category:** Searching | **Pattern:** Running top-k

## The problem

Given an array of at least three integers, return the three largest numbers in **ascending** order, **without sorting the input**. Duplicates count separately.

```
[141, 1, 17, -7, -17, -27, 18, 541, 8, 7, 7]  ->  [18, 141, 541]
[10, 5, 9, 10, 12]                             ->  [10, 10, 12]
[-1, -2, -3, -7, -17]                          ->  [-3, -2, -1]
```

## Step 1: Work an example by hand

Keep a tiny leaderboard with three slots: `[third, second, first]`. Read numbers one by one:

- If a number beats first place, everyone shifts down one place and it takes first.
- Else if it beats second, the old second becomes third and it takes second.
- Else if it beats third, it replaces third.
- Otherwise ignore it.

That is exactly what the code does, generalized as "find the highest slot this number beats, shift everything below it down".

## Step 2: Brute force

Sort and take the last three: O(n log n). The problem forbids sorting to make you think about a linear scan.

## Step 3: Linear scan with three slots

For each number `x`, check slots from the top (index 2 = largest) down to index 0:

- Find the first slot `i` (from the top) where the slot is empty or `x > slot[i]`.
- Shift slots `0..i-1` down (slot 0 falls off), then put `x` in slot `i`.

**Why use `null` for empty slots?** A common shortcut initializes the slots with 0 or with the first three numbers. Zero breaks on all-negative inputs (`[-1, -2, -3]` would return zeros). Using the smallest possible integer works but is a magic value. `null` says "empty" explicitly.

**Why strict `>`?** With `[10, 5, 9, 10, 12]`, the second `10` does not beat first place (10), but beats second place (9). So it lands in second, and duplicates are kept. Using `>=` would also be correct here but changes which duplicate occupies which slot.

## Step 4: The code

<!-- CODE:START -->

Full source: [`find_three_largest_numbers.dart`](find_three_largest_numbers.dart) (run it with `dart run`).

```dart
// Find Three Largest Numbers without sorting the input. Single pass, shifting a 3-slot window.
// O(n) time, O(1) space. Returns them in ascending order, duplicates allowed.

List<int> findThreeLargestNumbers(List<int> array) {
  final top = List<int?>.filled(3, null); // top[2] is the largest
  for (final x in array) {
    // Find the highest slot x beats, then shift smaller slots down.
    for (var i = 2; i >= 0; i--) {
      if (top[i] == null || x > top[i]!) {
        for (var j = 0; j < i; j++) {
          top[j] = top[j + 1];
        }
        top[i] = x;
        break;
      }
    }
  }
  return top.whereType<int>().toList();
}
```

<!-- CODE:END -->

### Walkthrough

- `final top = List<int?>.filled(3, null);` means three empty slots; `top[2]` is the largest.
- `for (var i = 2; i >= 0; i--)` looks for the highest slot `x` beats.
- `for (var j = 0; j < i; j++) top[j] = top[j + 1];` shifts the smaller slots down by one (the old `top[0]` is discarded).
- `top[i] = x; break;` places `x` and stops looking.
- `top.whereType<int>().toList()` removes any remaining `null`s (only possible if the input had fewer than three numbers).

## Step 5: Dry run

`[10, 5, 9, 10, 12]`:

| x | slot beaten (from top) | top after `[third, second, first]` |
|---|---|---|
| 10 | 2 (empty) | [null, null, 10] |
| 5 | 1 (empty) | [null, 5, 10] |
| 9 | 1 (9 > 5) | [5, 9, 10] |
| 10 | 1 (10 > 9, not > 10) | [9, 10, 10] |
| 12 | 2 (12 > 10) | [10, 10, 12] |

## Complexity

- **Time: O(n)**. The inner work per element is bounded by the constant 3.
- **Space: O(1)**.

## Generalizing to top-k

For arbitrary k, shifting slots costs O(k) per element (O(n * k) total). Better options:

| Method | Time | Space | Notes |
|---|---|---|---|
| Min-heap of size k | O(n log k) | O(k) | Push each element; pop when the heap exceeds k. Works on streams. |
| Quickselect | O(n) average | O(1) | Finds the k-th largest; see hard 46. Needs all data in memory. |
| Sort | O(n log n) | O(1) to O(n) | Simplest; fine when n is small. |

This is LeetCode #215 territory (k-th largest element), a very common interview question.

## Common mistakes

- Initializing slots with 0 (fails on negatives).
- Forgetting to shift lower slots when a new maximum arrives, which loses the old maximum.

## What to remember

A fixed-size leaderboard gives top-k in one pass. For large k, use a min-heap of size k.
