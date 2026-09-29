# Pattern Matcher

**Difficulty:** Hard | **Category:** Strings | **Pattern:** Enumerate one length, derive the other

## The problem

A **pattern** consists only of the characters `x` and `y`. Find strings for `x` and `y` such that replacing every `x` and every `y` in the pattern produces the given string. `x` must be non-empty; `y` may be empty only if the pattern contains no `y`. Return `[x, y]`, or `[]` if no assignment works.

```
pattern = "xxyxxy", string = "gogopowerrangergogopowerranger"  ->  ["go", "powerranger"]
pattern = "yxx",    string = "yomama"                           ->  ["ma", "yo"]
```

## Step 1: Count the unknowns

Let the pattern have `cx` x's and `cy` y's, and let the string have length n. Any valid assignment satisfies:

```
cx * len(x) + cy * len(y) = n
```

Once you choose `len(x)`, `len(y)` is forced: `(n - cx * len(x)) / cy` (it must be a non-negative integer). So there is really **only one free variable**: the length of `x`. Try each possible length.

## Step 2: Normalize so the pattern starts with x

If the pattern starts with `y`, swap every `x` and `y` in it. Now the pattern starts with `x`, which means **`x` is a prefix of the string**: once you know `len(x)`, you know `x` itself. Remember to swap the answer back at the end.

## Step 3: Locate y

The first `y` in the (normalized) pattern appears at pattern position `firstY`. Everything before it is x's, so in the string `y` starts at `firstY * len(x)` and has length `len(y)`.

## Step 4: Verify

Build the candidate string from the pattern and compare with the input. If it matches, you are done.

## Step 5: The code

<!-- CODE:START -->

Full source: [`pattern_matcher.dart`](pattern_matcher.dart) (run it with `dart run`).

```dart
// Pattern Matcher: pattern of 'x' and 'y'; find strings x and y (x != y is not required, but
// y may be empty only if the pattern has no 'y') such that substituting them yields `string`.
// Try every length for x; the length of y follows. O(n^2 + m) time, O(n + m) space.

List<String> patternMatcher(String pattern, String string) {
  if (pattern.isEmpty || pattern.length > string.length) return [];
  // Normalize so the pattern starts with 'x'; remember to swap the answer back.
  final swapped = pattern[0] != 'x';
  final p = swapped ? pattern.split('').map((c) => c == 'x' ? 'y' : 'x').join() : pattern;
  final countX = 'x'.allMatches(p).length, countY = p.length - countX;
  final firstY = p.indexOf('y');

  for (var lenX = 1; lenX * countX <= string.length; lenX++) {
    final rest = string.length - lenX * countX;
    if (countY == 0 && rest != 0) continue;
    if (countY > 0 && rest % countY != 0) continue;
    final lenY = countY == 0 ? 0 : rest ~/ countY;
    final x = string.substring(0, lenX);
    final y = countY == 0 ? '' : string.substring(firstY * lenX, firstY * lenX + lenY);
    final built = p.split('').map((c) => c == 'x' ? x : y).join();
    if (built == string) return swapped ? [y, x] : [x, y];
  }
  return [];
}
```

<!-- CODE:END -->

### Walkthrough

- `swapped` records whether the pattern was normalized.
- `countX`, `countY`, `firstY` are computed once.
- The loop tries every `lenX` such that the x's fit in the string; it skips lengths where `lenY` would not be an integer (or where the pattern has no y and the lengths do not add up).
- `x` is the string's prefix; `y` is read from its forced position.
- `built == string` verifies the candidate.

## Step 6: Dry run (first example)

`cx = 4`, `cy = 2`, `n = 30`, `firstY = 2`.

| lenX | lenY = (30 - 4 * lenX) / 2 | x | y | matches? |
|---|---|---|---|---|
| 1 | 13 | g | "gopowerranger" (from index 2) | no |
| 2 | 11 | go | "powerranger" (from index 4) | **yes** |

## Complexity

- **Time: O(n^2 + m)**: up to n candidate lengths, each built and compared in O(n) (m = pattern length).
- **Space: O(n + m)**.

## Common mistakes

- Forgetting to swap the result back after normalizing.
- Not handling a pattern with no `y` (then `y` is `""`).
- Trying all pairs of lengths (O(n^2) pairs times O(n) verification).

## Follow-ups

1. **Word Pattern (LeetCode #290):** the string is already split into words; check a bijection.
2. **Word Pattern II (#291):** arbitrary pattern letters; backtracking with a letter -> string map.
3. **Cracking the Coding Interview 16.18 (Pattern Matching):** this problem.

## What to remember

When lengths are linked by one equation, enumerate one length and derive the other. Normalizing a symmetric case (here, "starts with x") halves the logic.
