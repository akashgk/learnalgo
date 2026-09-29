# Underscorify Substring

**Difficulty:** Hard | **Category:** Strings | **Pattern:** Find match intervals, merge them, rebuild the string

## The problem

Given a string and a substring, wrap every occurrence of the substring in underscores. If occurrences **overlap** or **touch** each other, wrap the whole combined region once.

```
string    = "testthis is a testtest to see if testestest it works"
substring = "test"
->  "_test_this is a _testtest_ to see if _testestest_ it works"
```

- `testtest`: two touching matches: one region.
- `testestest`: matches at offsets 0, 3, 6 overlap (they share a `t`): one region.

## Step 1: Separate the two concerns

Trying to insert underscores while searching gets messy fast (should I close the underscore now, or will the next match continue this region?). Split the problem:

1. **Find** every occurrence as an interval `[start, end)`.
2. **Merge** overlapping or touching intervals (Merge Overlapping Intervals, medium 09).
3. **Rebuild** the string, adding `_` before each merged region and after it.

Each step is simple on its own.

## Step 2: Finding all matches, including overlapping ones

After finding a match at index `idx`, continue searching from `idx + 1`, **not** from `idx + substring.length`. Otherwise overlapping matches (like the second `test` inside `testestest`) are skipped.

## Step 3: Merging

Matches are found in increasing order of start, so merging happens on the fly: if the new match starts at or before the current region's end (`<=` makes touching matches merge), extend the region; otherwise start a new region.

## Step 4: The code

<!-- CODE:START -->

Full source: [`underscorify_substring.dart`](underscorify_substring.dart) (run it with `dart run`).

```dart
// Underscorify Substring: wrap every occurrence of `substring` in underscores, merging
// overlapping or adjacent occurrences into one wrapped region.
// Find occurrence intervals, merge, then build. O(n * m) time, O(n) space.

String underscorifySubstring(String string, String substring) {
  final intervals = <List<int>>[];
  var from = 0;
  while (true) {
    final idx = string.indexOf(substring, from);
    if (idx == -1) break;
    final end = idx + substring.length;
    if (intervals.isNotEmpty && idx <= intervals.last[1]) {
      intervals.last[1] = end; // overlapping or touching: extend
    } else {
      intervals.add([idx, end]);
    }
    from = idx + 1; // allow overlapping matches
  }
  final out = StringBuffer();
  var pos = 0;
  for (final [s, e] in intervals) {
    out
      ..write(string.substring(pos, s))
      ..write('_')
      ..write(string.substring(s, e))
      ..write('_');
    pos = e;
  }
  out.write(string.substring(pos));
  return out.toString();
}
```

<!-- CODE:END -->

### Walkthrough

- The `while (true)` loop uses `indexOf(substring, from)` to find each match and merges as it goes.
- `from = idx + 1` allows overlapping matches.
- The rebuild loop copies the text between regions, then `_`, the region, `_`.
- `StringBuffer` builds the result efficiently.

## Step 5: Dry run on "testestest"

| match at | interval | regions after |
|---|---|---|
| 0 | [0, 4) | [0, 4) |
| 3 | [3, 7) | 3 <= 4: [0, 7) |
| 6 | [6, 10) | 6 <= 7: [0, 10) |

One region `[0, 10)`: `_testestest_`.

## Complexity

- **Time: O(n * m)** with `indexOf`-style matching (n = string length, m = substring length). With the **KMP** algorithm (very hard 17), finding all matches is O(n + m).
- **Space: O(n)** for the intervals and the result.

## Common mistakes

- Advancing by the substring length after a match (misses overlapping matches).
- Using `<` in the merge (touching matches produce `_test__test_` instead of `_testtest_`).

## Follow-ups

1. **Add Bold Tag in String (LeetCode #616) / Bold Words in String (#758):** several keywords. Mark a boolean array of "bold" positions for all matches, then emit tags at the boundaries; a trie speeds up matching.
2. **Highlight search results** in a text editor: the same "find, merge, render" pipeline.

## What to remember

Split string-transformation problems into find (intervals), merge (interval logic), and rebuild (a buffer). Advance by one after a match if overlaps are possible.
