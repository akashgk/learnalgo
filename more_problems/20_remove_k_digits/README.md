# Remove K Digits

**Difficulty:** Medium | **Category:** Stacks / Greedy | **Pattern:** Monotonic stack greedy | **Source:** LeetCode 402; Striver A2Z

## The problem

Given a non-negative integer as a string, remove exactly `k` digits so the remaining number is as small as possible. Return it without leading zeros ("0" if empty).

```
"1432219", k = 3  ->  "1219"
"10200",   k = 1  ->  "200"
"10",      k = 2  ->  "0"
```

## Step 1: Work an example by hand

All results have the same length, `n - k`. Among numbers of equal length, the smaller one is decided by the **first differing digit from the left**. So the leftmost digits matter most.

`"1432219"`, k = 1: which single removal is best?

- remove 1: `432219`
- remove 4: `132219`  <- best
- remove 3: `142219`

Removing the 4 is best because 4 is followed by a **smaller** digit (3). Removing a digit that is followed by a smaller one makes the number smaller at that position. The best single removal is the **first digit that is bigger than its right neighbor** (the first "peak"). If the digits never decrease, remove the last digit.

## Step 2: Brute force

Repeat "find the first peak and remove it" k times: each pass is O(n), total **O(nk)**. Correct, and it is the greedy in slow motion.

## Step 3: Speed it up with a stack

After removing a peak, the digit before it may become the new peak (in `"1432219"`, after removing 4 we get `"132219"`, and now 3 > 2 is a peak). Rescanning from the start is wasteful: everything before the current position is already **non-decreasing**.

Keep the result built so far on a **stack** that is always non-decreasing. For each new digit `c`:

- while we still may remove (`k > 0`) and the top of the stack is **greater** than `c`, pop it (that top is a peak: bigger than the digit after it). Each pop uses one removal.
- push `c`.

After the scan, if removals remain, the stack is non-decreasing, so the largest digits are at the **end**: drop the last `k` digits. Finally strip leading zeros.

**Why is the greedy optimal?** Exchange argument. Suppose the kept digits so far are `P d` and the next digit is `c < d`, with a removal still available. Any result that keeps `d` has `P d ...`. Removing `d` instead (and keeping one digit that the other result removes later) gives a result of the same length that starts `P c ...`. Same prefix, smaller digit at the first difference: strictly smaller. So popping `d` is never a mistake.

## Step 4: The code

<!-- CODE:START -->

Full source: [`remove_k_digits.dart`](remove_k_digits.dart) (run it with `dart run`).

```dart
// Remove K Digits: remove k digits from a non-negative number string to make it as small as possible.
// Greedy with a monotonic (non-decreasing) stack: drop a digit whenever a smaller digit follows it.
// O(n) time, O(n) space.

String removeKdigits(String num, int k) {
  final stack = <int>[]; // digit code units
  var toRemove = k;
  for (final c in num.codeUnits) {
    // A larger digit before a smaller one is the most valuable removal available.
    while (toRemove > 0 && stack.isNotEmpty && stack.last > c) {
      stack.removeLast();
      toRemove--;
    }
    stack.add(c);
  }
  // Still owe removals: the stack is non-decreasing, so the largest digits are at the end.
  stack.length -= toRemove;
  // Strip leading zeros.
  var start = 0;
  while (start < stack.length && stack[start] == 48) {
    start++;
  }
  final result = String.fromCharCodes(stack.sublist(start));
  return result.isEmpty ? '0' : result;
}
```

<!-- CODE:END -->

### Walkthrough

- The stack holds code units; comparing code units of '0'..'9' is the same as comparing digits.
- `stack.length -= toRemove` truncates the leftover removals from the end.
- Leading zeros are skipped by index (48 is '0'). An empty result becomes "0".

## Step 5: Dry run

`"1432219"`, k = 3:

| digit | pops | stack after | k left |
|---|---|---|---|
| 1 | | 1 | 3 |
| 4 | | 1 4 | 3 |
| 3 | 4 | 1 3 | 2 |
| 2 | 3 | 1 2 | 1 |
| 2 | | 1 2 2 | 1 |
| 1 | 2 | 1 2 1 | 0 |
| 9 | | 1 2 1 9 | 0 |

Result `"1219"`.

## Complexity

- Time: **O(n)**. Each digit is pushed and popped at most once.
- Space: **O(n)** for the stack.

## Edge cases

| Input | Expected | Why |
|---|---|---|
| `"12345"`, k = 2 | `"123"` | no pops; truncate from the end |
| `"10200"`, k = 1 | `"200"` | pop 1 (1 > 0), then strip the leading 0 |
| `"10"`, k = 2 | `"0"` | everything removed |
| `"9"`, k = 1 | `"0"` | |

## Common mistakes

- Removing the largest digits (`"1432219"`: removing 9, 4, 3 gives `"1221"`, but the answer is `"1219"`; position matters, not size).
- Forgetting to truncate when removals remain after the scan.
- Returning `""` instead of `"0"`, or keeping leading zeros.
- Popping on `>=`: equal digits do not form a peak, and popping them wastes removals.

## Follow-ups you should be ready for

1. **Largest number after removing k digits.** Flip the comparison (keep a non-increasing stack).
2. **Remove Duplicate Letters / Smallest Subsequence of Distinct Characters (LeetCode 316, 1081).** Same stack, but you may only pop a character if it appears again later.
3. **Create Maximum Number (LeetCode 321).** Combines this with merging two sequences.

## What to remember

For the lexicographically smallest result, remove a digit whenever a smaller digit follows it, as far left as possible. A monotonic stack does that in one pass.
