# Common Characters

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Set intersection

## The problem

Given a non-empty list of non-empty strings, return the list of **unique** characters that appear in **every** string. Order does not matter (this solution returns them sorted so the output is deterministic).

```
["abc", "bcd", "cbaccd"]  ->  ["b", "c"]
["a", "b", "c"]           ->  []
```

## Step 1: Work an example by hand

For `["abc", "bcd", "cbaccd"]`:

- Characters of `"abc"`: {a, b, c}.
- Keep only those also in `"bcd"` = {b, c, d}: {b, c}.
- Keep only those also in `"cbaccd"` = {a, b, c, d}: {b, c}.

"Keep only what is also in the next one" is **set intersection**, repeated across all strings.

## Step 2: Approaches

**A. Count strings per character.** For each string, take its set of distinct characters, and increment a counter for each. Characters whose counter equals the number of strings are common. O(total characters) time.

**B. Running intersection (this code).** Start from the character set of one string and intersect with each string's set.

A small but meaningful optimization: start from the **shortest** string. Every common character must appear in it, so it gives the smallest starting set, and the intersections can only shrink from there.

## Step 3: The code

<!-- CODE:START -->

Full source: [`common_characters.dart`](common_characters.dart) (run it with `dart run`).

```dart
// Common Characters: characters present in every string. Intersect sets, starting from the
// shortest string. O(n * m) time, O(m) space (m = length of the shortest/longest string).

List<String> commonCharacters(List<String> strings) {
  final shortest = strings.reduce((a, b) => a.length <= b.length ? a : b);
  var common = shortest.split('').toSet();
  for (final s in strings) {
    common = common.intersection(s.split('').toSet());
  }
  return common.toList()..sort();
}
```

<!-- CODE:END -->

### Walkthrough

- `strings.reduce((a, b) => a.length <= b.length ? a : b)` finds the shortest string.
- `shortest.split('').toSet()` is its set of distinct characters.
- `common = common.intersection(s.split('').toSet())` keeps characters present in `s`.
- `common.toList()..sort()` returns a deterministic order.

## Step 4: Dry run

| string | its set | common after |
|---|---|---|
| (start, shortest "abc") | {a, b, c} | {a, b, c} |
| "abc" | {a, b, c} | {a, b, c} |
| "bcd" | {b, c, d} | {b, c} |
| "cbaccd" | {a, b, c, d} | {b, c} |

## Complexity

- **Time: O(n * m)**, where n is the number of strings and m the length of the longest one: building each string's set is O(m), and intersecting with a small set is fast.
- **Space: O(m)** for the per-string sets (bounded by the alphabet size, so O(1) for a fixed alphabet).

## Common mistakes

- Counting raw occurrences instead of distinct characters per string: `"cbaccd"` has three `c`s, but it should add only 1 to `c`'s counter in approach A.
- Returning duplicates.

## Follow-ups

1. **Keep multiplicity (LeetCode #1002, Find Common Characters):** `["bella", "label", "roller"]` -> `["e", "l", "l"]`. Keep the **minimum** count of each character across strings.
2. **Early exit:** stop as soon as `common` becomes empty.
3. **Fixed alphabet:** use a 26-element count array or a 26-bit mask per string; intersection becomes a bitwise AND.

## What to remember

"Present in all" = intersection. Start from the smallest candidate set.
