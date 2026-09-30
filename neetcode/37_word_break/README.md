# Word Break

**Difficulty:** Medium | **Category:** 1-D Dynamic Programming | **Pattern:** Prefix DP over split points | **Source:** LeetCode 139; NeetCode 150, Blind 75

## The problem

Can the string `s` be split into a sequence of dictionary words? Words may be reused.

```
"leetcode", ["leet", "code"]                            ->  true
"applepenapple", ["apple", "pen"]                       ->  true
"catsandog", ["cats", "dog", "sand", "and", "cat"]      ->  false
```

AlgoExpert hard 21 Numbers In Pi is the "minimum number of pieces" version of the same idea.

## Step 1: Brute force

Try every first word that is a prefix of `s`, then recurse on the rest. In the worst case (`"aaaa...ab"` with words `"a"`, `"aa"`, `"aaa"`) the same suffix is re-solved many times: exponential.

## Step 2: The subproblem

Whether the suffix (or prefix) from a given position can be segmented does not depend on how we got there. So define:

`dp[i]` = the first `i` characters can be segmented.

- `dp[0] = true` (empty prefix).
- `dp[i] = true` if for some word `w` ending at `i`, `dp[i - |w|]` is true and `s[i-|w| .. i)` equals `w`.

Answer: `dp[n]`.

## Step 3: Only try lengths that exist

Instead of every split point `j < i` (O(n^2) substrings), try only the **lengths of dictionary words**. With a hash set of words, each check is one substring and one lookup.

## Step 4: The code

<!-- CODE:START -->

Full source: [`word_break.dart`](word_break.dart) (run it with `dart run`).

```dart
// Word Break: can s be split into a sequence of dictionary words (words may be reused)?
// dp[i] = the prefix s[0..i) can be segmented. dp[i] is true if some dp[j] is true and s[j..i) is
// a word; only lengths that exist in the dictionary need checking.
// O(n * L * m) time for L distinct word lengths and substring cost m, O(n) space.

bool wordBreak(String s, List<String> wordDict) {
  final words = wordDict.toSet();
  final lengths = {for (final w in wordDict) w.length};
  final dp = List<bool>.filled(s.length + 1, false);
  dp[0] = true; // the empty prefix
  for (var i = 1; i <= s.length; i++) {
    for (final len in lengths) {
      if (len <= i && dp[i - len] && words.contains(s.substring(i - len, i))) {
        dp[i] = true;
        break;
      }
    }
  }
  return dp[s.length];
}
```

<!-- CODE:END -->

### Walkthrough

- `words` is a set for O(1) average lookups; `lengths` holds the distinct word lengths.
- `dp[i - len]` is checked before building the substring, so most substrings are never built.
- `break` once `dp[i]` is true.

## Step 5: Dry run

`"catsandog"`, dp by prefix length:

| i | prefix | dp[i] | reason |
|---|---|---|---|
| 0 | | T | empty |
| 3 | cat | T | "cat" |
| 4 | cats | T | "cats" |
| 7 | catsand | T | "cats" + "and" (or "cat" + "sand") |
| 9 | catsandog | F | "dog" would need dp[6] ("catsan"), which is false |

All other positions are false. Answer **false**.

## Complexity

- Time: **O(n * L * m)** where L = number of distinct word lengths and m = the cost of building and hashing a substring (up to the maximum word length).
- Space: **O(n)** plus the word set.

## Edge cases

- Empty string: true.
- Words longer than `s`: skipped by `len <= i`.

## Common mistakes

- Greedy longest match (`"aaaaaaa"` with `"aaaa"`, `"aaa"`: greedy takes 4 then fails on 3; the answer 3 + 4 exists).
- Recursion without memoization.

## Follow-ups you should be ready for

1. **Word Break II (LeetCode 140).** Return all sentences: backtracking with memoized suffix results; output can be exponential.
2. **Trie instead of a set.** Walk the trie forward from each true `dp` position; stops early when no word continues.
3. **Minimum number of words.** AlgoExpert hard 21 Numbers In Pi.

## What to remember

"Can this string be split into valid pieces?" is prefix DP: `dp[i]` is true if some valid piece ends at `i` and `dp` is true where it starts.
