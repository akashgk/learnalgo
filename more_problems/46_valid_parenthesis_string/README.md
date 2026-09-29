# Valid Parenthesis String

**Difficulty:** Medium | **Category:** Greedy / Strings | **Pattern:** Track the range of possible open counts | **Source:** LeetCode 678; Striver A2Z, NeetCode 150

## The problem

A string of `(`, `)` and `*`. Each `*` can be treated as `(`, `)`, or an empty string. Can the string be made a valid balanced parenthesis string?

```
"()"     ->  true
"(*)"    ->  true
"(*))"   ->  true     (* as '(')
"((*"    ->  false
"*)("    ->  false    (the last '(' can never close)
```

## Step 1: Without stars

Balanced parentheses need a counter of unmatched `(`: +1 for `(`, -1 for `)`. The string is valid if the counter **never goes negative** and **ends at 0**. (See AlgoExpert medium 60 Balanced Brackets for the stack version.)

## Step 2: Brute force

Each star has 3 options: try all `3^k` assignments and check each in O(n). Exponential.

A DP over `(index, open count)` is O(n^2): `can(i, open)` = can the suffix from `i` be completed with `open` unmatched `(`. That is a solid answer. But there is an O(n), O(1) insight.

## Step 3: Track the set of possible counts

Instead of committing to one choice per star, track **every** open count reachable after the prefix. Each character maps the set of counts:

- `(`: every count goes up by 1.
- `)`: every count goes down by 1.
- `*`: every count `c` becomes `c - 1`, `c`, or `c + 1`.

**Claim: the reachable set is always a contiguous range `[lo, hi]`.** It starts as `{0}`. Shifting a range by ±1 keeps it a range, and a star turns `[lo, hi]` into `[lo - 1, hi + 1]`, also a range. So two integers describe it completely.

Two corrections:

- A count below 0 is not a real state (a prefix with more `)` than `(` is already broken). If `lo` drops below 0, clamp it to 0: the negative states are simply discarded.
- If `hi` drops below 0, even the most optimistic choice (every star as `(`) has too many `)`: return false.

At the end, the string is valid if **0 is in the range**, which after clamping means `lo == 0`.

## Step 4: The code

<!-- CODE:START -->

Full source: [`valid_parenthesis_string.dart`](valid_parenthesis_string.dart) (run it with `dart run`).

```dart
// Valid Parenthesis String: '(' , ')' and '*' where '*' may be '(', ')' or empty. Can it be balanced?
// Greedy range tracking: keep the minimum and maximum possible number of unmatched '('.
// O(n) time, O(1) space.

bool checkValidString(String s) {
  var lo = 0, hi = 0; // the set of reachable open counts is exactly [lo, hi]
  for (final ch in s.split('')) {
    if (ch == '(') {
      lo++;
      hi++;
    } else if (ch == ')') {
      lo--;
      hi--;
    } else {
      lo--; // '*' as ')'
      hi++; // '*' as '('
    }
    if (hi < 0) return false; // even treating every '*' as '(' we have too many ')'
    if (lo < 0) lo = 0; // a negative open count is not a real state; drop it
  }
  return lo == 0; // some choice closes everything
}
```

<!-- CODE:END -->

### Walkthrough

- `lo` is the minimum possible open count, `hi` the maximum.
- `if (hi < 0) return false;` the early exit.
- `if (lo < 0) lo = 0;` drops impossible negative states.
- `return lo == 0;` means some assignment closes everything.

## Step 5: Dry run

`"(*))"`:

| char | lo | hi | note |
|---|---|---|---|
| ( | 1 | 1 | |
| * | 0 | 2 | |
| ) | -1 -> 0 | 1 | clamp |
| ) | -1 -> 0 | 0 | clamp |
| end | 0 | | lo == 0: **true** |

`"*)("`:

| char | lo | hi |
|---|---|---|
| * | -1 -> 0 | 1 |
| ) | -1 -> 0 | 0 |
| ( | 1 | 1 |
| end | 1 | lo != 0: **false** |

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- Empty string: true.
- Only stars: true (all empty).
- A `)` before anything that could open it: `hi` goes negative, false.

## Common mistakes

- Checking only that the counts could end at 0, without ever rejecting a negative prefix.
- Clamping `hi` instead of `lo`.
- Two-stack approach errors: the stack solution (indices of `(` and `*`, matching `)` greedily, then matching leftover `(` with **later** stars) is correct but easy to get wrong on the "later" condition.

## Follow-ups you should be ready for

1. **Two-pass alternative.** Left to right treating every star as `(` (never go negative), then right to left treating every star as `)` (never go negative). Valid if both passes succeed.
2. **Minimum Add to Make Parentheses Valid (LeetCode 921), Longest Valid Parentheses (LeetCode 32).** Counter and stack techniques; see AlgoExpert very_hard 36 Longest Balanced Substring.
3. **Generate all valid strings (LeetCode 22).** Backtracking with open and close counters; see AlgoExpert hard 42 Generate Div Tags.

## What to remember

When each wildcard could be several things, track the **range** of reachable states instead of branching. For parentheses, the range of open counts is always contiguous, so two integers suffice.
