# Interweaving Strings

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Recursion with memoization -> 2D DP over two prefixes

## The problem

Given strings `one`, `two`, and `three`, return whether `three` can be formed by **interweaving** `one` and `two`: using all characters of both, and keeping the relative order of characters within each string.

```
one = "algoexpert", two = "your-dream-job", three = "your-algodream-expertjob"  ->  true
one = "aabcc", two = "dbbca", three = "aadbbcbcac"  ->  true
one = "aabcc", two = "dbbca", three = "aadbbbaccc"  ->  false
```

## Step 1: A quick filter

If `len(one) + len(two) != len(three)`, the answer is false.

## Step 2: Why greedy fails

Walk `three` and at each character take it from whichever string matches. When **both** match, which one? Example: `one = "aab"`, `two = "aac"`, `three = "aacaab"`. Taking from `one` first uses up `aa` from `one` and then gets stuck at `c`. The correct choice at the start is `two`. We need to explore both options.

## Step 3: Recursion

State: `(i, j)` = we have used `i` characters of `one` and `j` of `two`. The next character of `three` is at index `k = i + j`.

```
can(i, j):
    if i + j == len(three): return true
    return (i < len(one) and one[i] == three[i+j] and can(i+1, j))
        or (j < len(two) and two[j] == three[i+j] and can(i, j+1))
```

Without caching, this can branch twice at every step: exponential. But there are only `(n + 1) * (m + 1)` distinct states `(i, j)`, so **memoize** them: O(n * m).

## Step 4: Tabulation (bottom-up)

`ok[i][j]` = the first `i` characters of `one` and the first `j` of `two` can form the first `i + j` of `three`.

```
ok[0][0] = true
ok[i][j] = (ok[i-1][j] and one[i-1] == three[i+j-1])
        or (ok[i][j-1] and two[j-1] == three[i+j-1])
```

Each row depends only on the previous row and the current row's left neighbor: one rolling row of size `m + 1`.

## Step 5: The code

<!-- CODE:START -->

Full source: [`interweaving_strings.dart`](interweaving_strings.dart) (run it with `dart run`).

```dart
// Interweaving Strings: can `three` be formed by interleaving `one` and `two`, keeping each
// one's character order? 2D DP (rolling row). O(n * m) time, O(m) space.

bool interweavingStrings(String one, String two, String three) {
  final n = one.length, m = two.length;
  if (n + m != three.length) return false;
  // ok[j] = can one[0..i) and two[0..j) form three[0..i+j)
  final ok = List<bool>.filled(m + 1, false)..[0] = true;
  for (var j = 1; j <= m; j++) {
    ok[j] = ok[j - 1] && two[j - 1] == three[j - 1];
  }
  for (var i = 1; i <= n; i++) {
    ok[0] = ok[0] && one[i - 1] == three[i - 1];
    for (var j = 1; j <= m; j++) {
      final k = i + j - 1;
      ok[j] = (ok[j] && one[i - 1] == three[k]) || (ok[j - 1] && two[j - 1] == three[k]);
    }
  }
  return ok[m];
}
```

<!-- CODE:END -->

### Walkthrough

- The length check comes first.
- `ok` is the rolling row. Before the main loop it is row 0: only characters from `two` used.
- For each `i`, `ok[0]` is updated (only characters from `one`), then each `ok[j]`:
  - `ok[j]` on the right-hand side still holds the **previous row's** value: "came from `one`";
  - `ok[j - 1]` already holds the **current row's** value: "came from `two`".

## Step 6: Dry run (small): one = "ab", two = "c", three = "acb"

| i \ j | 0 | 1 (c) |
|---|---|---|
| 0 | true | "c" vs "a": false |
| 1 (a) | "a" == "a": true | from top: false; from left: true and "c" == three[1] = "c": **true** |
| 2 (b) | "ab" vs "ac": false | from top: true and "b" == three[2] = "b": **true** |

`ok[2][1]` is true.

## Complexity

- **Time: O(n * m)**.
- **Space: O(m)** with one rolling row (O(n * m) with a full table or memo map).

## Common mistakes

- Greedy choice when both strings match.
- Forgetting the length check (the DP can accept a prefix otherwise).

## Follow-ups

1. **Interleaving String (LeetCode #97):** identical.
2. **Top-down memo version:** often easier to write first in an interview; then offer the bottom-up version for the space optimization.

## What to remember

When a recursion branches but its state is small (two indices), memoize the state. Then convert to a table and roll the rows.
