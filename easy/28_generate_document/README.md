# Generate Document

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Frequency counting

## The problem

You have a string of available characters and a document string. Can you produce the document using the available characters, where each character can be used at most once? Case, spaces, and punctuation all count. An empty document can always be generated.

```
characters = "Bste!hetsi ogEAxpelrt x ", document = "AlgoExpert is the Best!"  ->  true
characters = "A", document = "a"                                                ->  false
characters = "abc", document = ""                                               ->  true
```

## Step 1: Work an example by hand

Think of the characters as a bag of letter tiles. To spell the document, take one tile per document character. You fail when you need a tile the bag no longer has.

So you need to know **how many of each character** the bag contains, and then subtract as you use them.

## Step 2: Brute force

For every character of the document, count its occurrences in both strings and compare. O(m * (n + m)) where m is the document length.

Or: for each document character, search the available characters for an unused copy and mark it used. O(m * n).

Both repeat the same counting work over and over.

## Step 3: Optimize with a frequency map

**Duplicated work:** counting the same character in `characters` many times. Count everything **once**:

1. Build a map `character -> count` from `characters`. O(n).
2. Walk the document. For each character, if its count is 0, fail; otherwise decrement. O(m).

Quick early exit: if the document is longer than the available characters, it cannot fit.

## Step 4: The code

<!-- CODE:START -->

Full source: [`generate_document.dart`](generate_document.dart) (run it with `dart run`).

```dart
// Generate Document: can `document` be built from the available characters (each used once)?
// Count available chars, then consume. O(n + m) time, O(c) space.

bool generateDocument(String characters, String document) {
  final counts = <int, int>{};
  for (final c in characters.codeUnits) {
    counts.update(c, (v) => v + 1, ifAbsent: () => 1);
  }
  for (final c in document.codeUnits) {
    final left = counts[c] ?? 0;
    if (left == 0) return false;
    counts[c] = left - 1;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `final counts = <int, int>{};` maps character codes to available counts.
- `counts.update(c, (v) => v + 1, ifAbsent: () => 1)` increments or inserts.
- `final left = counts[c] ?? 0;` treats characters never seen as having count 0.
- `if (left == 0) return false;` means we need a tile we do not have.
- `counts[c] = left - 1;` uses one tile.

## Step 5: Dry run

`characters = "aab"`, `document = "aba"`:

| step | counts |
|---|---|
| after counting | {a: 2, b: 1} |
| use 'a' | {a: 1, b: 1} |
| use 'b' | {a: 1, b: 0} |
| use 'a' | {a: 0, b: 0} -> true |

With `document = "abb"`, the second `b` finds count 0 -> false.

## Complexity

- **Time: O(n + m)**.
- **Space: O(c)**, the number of distinct characters (bounded by the alphabet, so O(1) for ASCII).

## Common mistakes

- Using a set instead of counts (ignores multiplicity).
- Forgetting spaces and punctuation count as characters.
- Checking only that every document character **exists** in `characters`.

## Follow-ups

1. **Ransom Note (LeetCode #383):** identical.
2. **Fixed alphabet:** a `List<int>` of size 128 (ASCII) or 26 is faster than a hash map. Mention the trade-off.
3. **Many documents against the same characters:** build the count map once and reuse a copy per query.

## What to remember

"Can A be built from B's parts?" -> count B's parts once, then consume them while reading A.
