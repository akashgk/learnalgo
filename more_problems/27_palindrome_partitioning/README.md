# Palindrome Partitioning

**Difficulty:** Medium | **Category:** Recursion / Backtracking | **Pattern:** Backtracking over cut positions + palindrome DP table | **Source:** LeetCode 131; Striver A2Z, NeetCode 150

## The problem

Return every way to split a string into pieces that are all palindromes.

```
"aab"  ->  [["a", "a", "b"], ["aa", "b"]]
"aba"  ->  [["a", "b", "a"], ["aba"]]
```

This asks for **all** partitions. The minimum number of cuts is a different (DP) problem: AlgoExpert very_hard 13 Palindrome Partitioning Min Cuts.

## Step 1: The decision at each step

Standing at position `start`, the next piece is `s[start..end]` for some `end >= start`. It must be a palindrome. After choosing it, the rest of the string, starting at `end + 1`, is partitioned the same way. When `start == n`, the pieces chosen so far form one complete partition.

That is a recursion with a loop over `end`: backtracking.

## Step 2: The recursion tree for "aab"

```
start 0
|- "a"   -> start 1
|           |- "a"  -> start 2
|           |          |- "b" -> start 3 => [a, a, b]
|           |- "ab" (not a palindrome)
|- "aa"  -> start 2
|           |- "b" -> start 3 => [aa, b]
|- "aab" (not a palindrome)
```

## Step 3: Avoid re-checking palindromes

The recursion asks "is `s[i..j]` a palindrome?" for the same `(i, j)` many times in different branches. Checking each time costs O(n). Precompute a table once:

```
isPal[i][j] = s[i] == s[j] && (j - i < 2 || isPal[i + 1][j - 1])
```

A substring is a palindrome if its ends match and its inside is a palindrome (length 0 or 1 insides are trivially palindromes). Fill it with `i` from `n - 1` down to 0 so that `isPal[i + 1][j - 1]` is ready. O(n^2) time and space, then each check is O(1).

## Step 4: The code

<!-- CODE:START -->

Full source: [`palindrome_partitioning.dart`](palindrome_partitioning.dart) (run it with `dart run`).

```dart
// Palindrome Partitioning: all ways to cut a string into pieces that are all palindromes.
// Backtracking over the end of the next piece, with a precomputed palindrome table.
// O(n * 2^n) time in the worst case ("aaaa..."), O(n^2) space for the table.

List<List<String>> partition(String s) {
  final n = s.length;
  // isPal[i][j]: s[i..j] is a palindrome. Filled from the bottom so isPal[i+1][j-1] is ready.
  final isPal = List.generate(n, (_) => List<bool>.filled(n, false));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = i; j < n; j++) {
      isPal[i][j] = s[i] == s[j] && (j - i < 2 || isPal[i + 1][j - 1]);
    }
  }
  final result = <List<String>>[];
  final path = <String>[];
  void dfs(int start) {
    if (start == n) {
      result.add([...path]);
      return;
    }
    for (var end = start; end < n; end++) {
      if (!isPal[start][end]) continue;
      path.add(s.substring(start, end + 1));
      dfs(end + 1);
      path.removeLast();
    }
  }

  dfs(0);
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- The table loop fills row `i` after row `i + 1`, as required.
- `dfs(start)` loops `end` from `start` to `n - 1` and only recurses when `s[start..end]` is a palindrome.
- `path` is shared, copied when a partition is complete.

## Step 5: Dry run

`"aab"`: the table has `isPal[0][0], [1][1], [2][2]` true, `isPal[0][1]` true ("aa"), `isPal[1][2]` false ("ab"), `isPal[0][2]` false ("aab"). The recursion follows the tree above and produces `[a, a, b]`, then `[aa, b]`.

## Complexity

- Time: **O(n * 2^n)** in the worst case. A string like `"aaaa"` has every substring a palindrome, so every one of the `2^(n-1)` ways to cut is valid, and each costs O(n) to copy.
- Space: **O(n^2)** for the table, **O(n)** recursion depth.

## Edge cases

- One character: `[[c]]`.
- All equal characters: `2^(n-1)` partitions.
- No repeated characters: exactly one partition (all single characters).

## Common mistakes

- Filling the palindrome table in the wrong order (reading `isPal[i + 1][j - 1]` before it is computed).
- Using `substring(start, end)` with an exclusive end off by one.
- Not copying `path` on success.

## Follow-ups you should be ready for

1. **Minimum cuts (LeetCode 132).** DP: `cuts[j] = min over palindromic s[i..j] of cuts[i - 1] + 1`. O(n^2).
2. **Count partitions only.** DP: `ways[j] = sum over palindromic s[i..j] of ways[i - 1]`.
3. **Word Break II (LeetCode 140).** Identical structure with "is in the dictionary" instead of "is a palindrome".

## What to remember

"All ways to split a string into valid pieces" is backtracking over the end of the next piece. Precompute the validity test when it repeats across branches.
