# Numbers In Pi

**Difficulty:** Hard | **Category:** Dynamic Programming | **Pattern:** Word break (minimum number of pieces)

## The problem

Given a string of digits of pi and a list of "favorite numbers" (digit strings), insert the **minimum number of spaces** into the pi string so that every resulting piece is one of the favorite numbers. Return that minimum, or -1 if it is impossible.

```
pi = "3141592653589793238462643383279"
favorites = ["314159265358979323846", "26433", "8", "3279", "314159265", "35897932384626433832", "79"]
->  2    ("314159265 | 35897932384626433832 | 79")
```

(Using `"314159265358979323846" | "26433" | "8" | "3279"` also works but needs 3 spaces.)

## Step 1: Recognize the problem

This is **Word Break**: can a string be split into dictionary words? Here, additionally, we minimize the number of pieces.

Spaces = pieces - 1.

## Step 2: Brute force

Try every way to cut the string: at each position, try every favorite that matches as a prefix, and recurse on the rest. Without caching, the same suffix is solved many times: exponential.

## Step 3: DP over suffixes

`best[i]` = the minimum number of pieces to split the suffix starting at index `i`. `best[n] = 0` (an empty suffix needs no pieces).

```
best[i] = min over all end > i where pi[i..end) is a favorite of (1 + best[end])
```

Fill from right to left. Answer: `best[0] - 1` spaces, or -1 if `best[0]` is infinite.

Store the favorites in a **hash set** so "is this substring a favorite?" is an O(length) hash plus an O(1) lookup.

## Step 4: The code

<!-- CODE:START -->

Full source: [`numbers_in_pi.dart`](numbers_in_pi.dart) (run it with `dart run`).

```dart
// Numbers In Pi: split the digits of pi into favorite numbers using the fewest spaces.
// DP over suffixes: minSpaces(i) = min over favorites starting at i of 1 + minSpaces(end).
// O(n^3 + m) time with substring hashing (n = digits of pi, m = total favorite length), O(n + m) space.

int numbersInPi(String pi, List<String> numbers) {
  final favorites = numbers.toSet();
  const inf = 1 << 30;
  // best[i] = min number of pieces to split pi[i..]; best[n] = 0.
  final best = List<int>.filled(pi.length + 1, inf)..[pi.length] = 0;
  for (var i = pi.length - 1; i >= 0; i--) {
    for (var end = i + 1; end <= pi.length; end++) {
      if (best[end] != inf && favorites.contains(pi.substring(i, end)) && best[end] + 1 < best[i]) {
        best[i] = best[end] + 1;
      }
    }
  }
  return best[0] == inf ? -1 : best[0] - 1; // spaces = pieces - 1
}
```

<!-- CODE:END -->

### Walkthrough

- `favorites` is a set for fast membership.
- `best` is filled from `n - 1` down to 0.
- For each start `i`, every possible end is tried; a transition is valid if the rest is solvable (`best[end] != inf`) and the piece is a favorite.
- Final line converts pieces to spaces.

## Complexity

- **Time: O(n^3)** in the worst case: O(n^2) (start, end) pairs, and each substring costs up to O(n) to build and hash. Limiting `end - i` to the length of the longest favorite brings it down to O(n * L^2). Walking a **trie** of favorites from each start gives O(n * L).
- **Space: O(n + m)**, m = total length of the favorites.

## Common mistakes

- Returning the number of pieces instead of spaces.
- Greedy longest match (can fail: a long match may leave a remainder that cannot be split).

## Follow-ups

1. **Word Break (LeetCode #139):** boolean version.
2. **Word Break II (#140):** return all splits; memoize the list of splits per suffix.
3. **Concatenated Words (#472):** each word built from other words in the same list.

## What to remember

Splitting a string into dictionary pieces is DP over suffixes (or prefixes): try every piece that starts here and combine with the best answer for the rest.
