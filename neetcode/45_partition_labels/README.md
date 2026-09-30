# Partition Labels

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Extend the current part to the last occurrence of every letter in it | **Source:** LeetCode 763; NeetCode 150

## The problem

Split the string into as many parts as possible so that each letter appears in **at most one** part. Return the sizes of the parts, in order.

```
"ababcbacadefegdehijhklij"  ->  [9, 7, 8]
 ababcbaca | defegde | hijhklij
```

## Step 1: Where can a part end?

If a part contains letter `a`, it must also contain the **last** `a` in the string (otherwise `a` would appear in two parts). So a part that starts at `start` must extend at least to `last[c]` for every letter `c` it contains. That requirement grows as the part picks up more letters.

## Step 2: Greedy scan

Precompute `last[c]` for every letter. Then scan with `end` = the furthest last-occurrence of any letter seen in the current part:

- at index `i`, `end = max(end, last[s[i]])`;
- if `i == end`, every letter in `s[start..i]` has its last occurrence inside the part: cut here, and start a new part.

**Why cutting as early as possible is optimal:** each cut happens at the earliest index where a cut is legal. Cutting later would only merge parts, reducing the count; cutting earlier is illegal. So the number of parts is maximized.

## Step 3: The code

<!-- CODE:START -->

Full source: [`partition_labels.dart`](partition_labels.dart) (run it with `dart run`).

```dart
// Partition Labels: split the string into as many parts as possible so that each letter appears in
// at most one part; return the part sizes.
// Record each letter's last index. Scan, extending the current part's end to the last occurrence of
// every letter seen; when the scan reaches that end, close the part. O(n) time, O(1) space (26).

List<int> partitionLabels(String s) {
  final last = List<int>.filled(26, 0);
  for (var i = 0; i < s.length; i++) {
    last[s.codeUnitAt(i) - 97] = i;
  }
  final sizes = <int>[];
  var start = 0, end = 0;
  for (var i = 0; i < s.length; i++) {
    final l = last[s.codeUnitAt(i) - 97];
    if (l > end) end = l; // this letter forces the part to reach at least l
    if (i == end) {
      // Every letter in s[start..end] has its last occurrence inside: safe to cut here.
      sizes.add(end - start + 1);
      start = i + 1;
    }
  }
  return sizes;
}
```

<!-- CODE:END -->

### Walkthrough

- The first loop records each letter's last index (later occurrences overwrite earlier ones).
- `end` only grows within a part; `i == end` is the cut condition.

## Step 4: Dry run

Last occurrences: a 8, b 5, c 7, d 14, e 15, f 11, g 13, h 19, i 22, j 23, k 20, l 21.

| i range | letters seen | end | cut at |
|---|---|---|---|
| 0..8 | a, b, c | 8 | 8: size 9 |
| 9..15 | d, e, f, g | 15 | 15: size 7 |
| 16..23 | h, i, j, k, l | 23 | 23: size 8 |

## Complexity

- Time: **O(n)**.
- Space: **O(1)** (26 last indices).

## Edge cases

- All distinct letters: every part has size 1.
- One letter at both ends (`"eccbbbbdec"`): one part.

## Common mistakes

- Cutting when the current letter's own last occurrence is reached (other letters in the part may extend further).
- Returning the parts instead of their sizes (or the other way around): read the question.

## Follow-ups you should be ready for

1. **Merge Intervals view.** Each letter defines the interval `[first, last]`; merging overlapping intervals gives exactly these parts (AlgoExpert medium 9).
2. **Return the substrings.** Use `start` and `end` to slice.

## What to remember

A part must reach the last occurrence of every letter inside it. Track the furthest such index and cut exactly when the scan reaches it.
