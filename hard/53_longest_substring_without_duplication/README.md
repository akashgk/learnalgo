# Longest Substring Without Duplication

**Difficulty:** Hard | **Category:** Strings | **Pattern:** Sliding window with last-seen positions

## The problem

Return the longest substring of a string that contains **no repeated characters**. Assume a unique answer.

```
"clementisacap"  ->  "mentisac"
"abba"           ->  "ab"
```

## Step 1: Brute force

Check every substring for duplicates with a set: O(n^3), or O(n^2) if you extend each start with an incremental set.

## Step 2: Sliding window

Keep a window `[start, i]` that has no duplicates. Move `i` forward one character at a time:

- If `s[i]` does not appear in the window, the window simply grows.
- If it **does** appear, the window must start after that earlier occurrence, or it would contain the character twice.

Record the longest window seen.

## Step 3: Jump instead of crawl

Store each character's **last seen index** in a map. When `s[i]` was last seen at `prev` and `prev >= start` (inside the window), jump `start` directly to `prev + 1`, instead of removing characters one by one.

The guard `prev >= start` is essential: an occurrence **before** the window must not move `start` backward. Test with `"abba"`:

| i | char | last seen | start after | window |
|---|---|---|---|---|
| 0 | a | none | 0 | "a" |
| 1 | b | none | 0 | "ab" |
| 2 | b | 1 (inside) | 2 | "b" |
| 3 | a | 0 (**before** start 2) | 2 (unchanged) | "ba" |

Without the guard, step 3 would set `start = 1`, and the window `"bba"` would contain `b` twice.

## Step 4: The code

<!-- CODE:START -->

Full source: [`longest_substring_without_duplication.dart`](longest_substring_without_duplication.dart) (run it with `dart run`).

```dart
// Longest Substring Without Duplication. Sliding window with last-seen index per character.
// O(n) time, O(min(n, alphabet)) space.

String longestSubstringWithoutDuplication(String string) {
  final lastSeen = <int, int>{};
  var start = 0, bestStart = 0, bestLen = 0;
  for (var i = 0; i < string.length; i++) {
    final c = string.codeUnitAt(i);
    final prev = lastSeen[c];
    if (prev != null && prev >= start) start = prev + 1; // jump past the duplicate
    lastSeen[c] = i;
    if (i - start + 1 > bestLen) {
      bestLen = i - start + 1;
      bestStart = start;
    }
  }
  return string.substring(bestStart, bestStart + bestLen);
}
```

<!-- CODE:END -->

### Walkthrough

- `lastSeen` maps character codes to their latest index.
- `if (prev != null && prev >= start) start = prev + 1;` is the jump with the guard.
- `lastSeen[c] = i;` updates the position.
- `bestStart` and `bestLen` record the longest window; the substring is built once at the end.

## Step 5: Dry run (key steps of "clementisacap")

| i | char | action | window | best |
|---|---|---|---|---|
| 0..2 | c, l, e | grow | "cle" | "cle" |
| 3 | m | grow | "clem" | "clem" |
| 4 | e | e last at 2: start = 3 | "me" | "clem" |
| 5..10 | n, t, i, s, a, c | grow (the old c at 0 is before start) | "mentisac" | "mentisac" |
| 11 | a | a last at 10: start = 11 | "a" | "mentisac" |
| 12 | p | grow | "ap" | "mentisac" |

## Complexity

- **Time: O(n)**: each index is processed once; `start` only moves forward.
- **Space: O(min(n, alphabet size))** for the map.

## Common mistakes

- Missing the `prev >= start` guard (the `"abba"` bug).
- Recomputing substrings on every step (extra O(n) per step).

## The general sliding-window template

```
for right in 0..n-1:
    add s[right] to the window
    while the window is invalid: remove s[left], left++      (or jump left directly)
    update the answer with the valid window [left, right]
```

It solves: Minimum Window Substring (very hard 35), Longest Repeating Character Replacement (LeetCode #424), Longest Substring with At Most K Distinct Characters (#340), Fruit Into Baskets (#904).

## What to remember

Grow the window on the right; when it breaks the rule, move the left edge. With "last seen" indices, the left edge can jump, but never backward.
