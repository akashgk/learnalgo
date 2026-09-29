# Validate Subsequence

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Two pointers (greedy matching)

## The problem

Given two arrays of integers, `array` and `sequence`, decide whether `sequence` is a **subsequence** of `array`. A subsequence is a set of numbers that appear in `array` in the same relative order, but not necessarily next to each other.

```
array    = [5, 1, 22, 25, 6, -1, 8, 10]
sequence = [1, 6, -1, 10]          ->  true   (1 ... 6 ... -1 ... 10 appear in order)
sequence = [1, 6, 10, -1]          ->  false  (10 comes after -1 in array)
sequence = [22, 25, 22]            ->  false  (only one 22 exists)
```

A single number and the whole array are both valid subsequences.

### Clarifying questions

| Question | Why it matters |
|---|---|
| Can `sequence` be empty? | An empty sequence is trivially a subsequence. Handle it or confirm it cannot happen. |
| Can values repeat? | Yes in general. Each element of `array` may be used at most once, which matters for `[22, 25, 22]`. |
| Subsequence or substring? | A **substring** (contiguous) is a different, harder-to-match requirement. Confirm "gaps are allowed". |

## Step 1: Work an example by hand

`array = [5, 1, 22, 25, 6, -1, 8, 10]`, `sequence = [1, 6, -1, 10]`.

Put your finger on the first number you are looking for, `1`. Read `array` left to right: `5` no, `1` yes. Now look for `6`: `22` no, `25` no, `6` yes. Look for `-1`: `-1` yes. Look for `10`: `8` no, `10` yes. You found all four, so the answer is true.

Your finger only ever moved forward in both arrays. That is two pointers.

## Step 2: Brute force

A literal brute force would try every way to choose `len(sequence)` positions from `array` and check whether the values match in order. That is `C(n, m)` choices, exponential in the worst case. No one would code it, but naming it helps: it tells you the question is about **choosing positions in order**, and the greedy walk below makes the choice instantly.

## Step 3: Optimize: the greedy walk

Keep one pointer `seqIdx` into `sequence` (the value you are waiting for) and scan `array` once:

- If the current `array` value equals `sequence[seqIdx]`, it is a match: advance `seqIdx`.
- Otherwise skip it.
- At the end, the answer is `seqIdx == sequence.length` (every element was matched).

### Why is matching as early as possible correct?

This is the proof an interviewer may ask for. Suppose `sequence[k]` could be matched at two positions in `array`, an earlier one `p` and a later one `q`. Matching at `p` leaves the suffix `array[p+1 ..]` for the rest of the sequence, which **contains** the suffix `array[q+1 ..]` that matching at `q` would leave. A bigger remaining suffix can never make it harder to match what is left. So the earliest match is never worse. This is called a **greedy stays ahead** argument.

## Step 4: The code

<!-- CODE:START -->

Full source: [`validate_subsequence.dart`](validate_subsequence.dart) (run it with `dart run`).

```dart
// Validate Subsequence
// Walk the main array once, advancing a pointer into the sequence on each match.
// O(n) time, O(1) space.

bool isValidSubsequence(List<int> array, List<int> sequence) {
  var seqIdx = 0;
  for (final value in array) {
    if (seqIdx == sequence.length) break;
    if (value == sequence[seqIdx]) seqIdx++;
  }
  return seqIdx == sequence.length;
}
```

<!-- CODE:END -->

### Walkthrough

- `var seqIdx = 0;` is the index in `sequence` of the next value we still need.
- `for (final value in array)` is the single forward scan.
- `if (seqIdx == sequence.length) break;` is an early exit: everything has already matched, so the rest of `array` is irrelevant. It also prevents reading `sequence[seqIdx]` past the end.
- `if (value == sequence[seqIdx]) seqIdx++;` consumes one element of `sequence` on a match.
- `return seqIdx == sequence.length;` is true only if every element was matched.

## Step 5: Dry run

`array = [5, 1, 22, 25, 6, -1, 8, 10]`, `sequence = [1, 6, -1, 10]`:

| value | waiting for | match? | seqIdx after |
|---|---|---|---|
| 5 | 1 | no | 0 |
| 1 | 1 | yes | 1 |
| 22 | 6 | no | 1 |
| 25 | 6 | no | 1 |
| 6 | 6 | yes | 2 |
| -1 | -1 | yes | 3 |
| 8 | 10 | no | 3 |
| 10 | 10 | yes | 4 |

`seqIdx == 4 == sequence.length`, so the result is `true`.

Now `sequence = [1, 6, 10, -1]`: after matching `1` and `6`, we wait for `10`. `-1` and `8` do not match, `10` matches (seqIdx 3), and then `array` ends while we still wait for `-1`. Result: `false`.

## Complexity

- **Time: O(n)** where n is the length of `array`. One pass; each step is O(1).
- **Space: O(1)**. One integer.

## Edge cases

| Case | Result | Why |
|---|---|---|
| `sequence` empty | true | `seqIdx` starts equal to `sequence.length` (0) |
| `sequence` longer than `array` | false | cannot match more elements than exist |
| `sequence == array` | true | every element matches in order |
| repeated values, e.g. `[1, 1, 6, 1]` vs `[1, 1, 1, 6]` | false | the third `1` in `sequence` consumes the last `1` of `array`, after the 6 |

## Common mistakes

- Using a hash set of `array` values. It ignores order and multiplicity, so `[1, 6, 10, -1]` would wrongly be true.
- Looping over `sequence` in the outer loop and searching `array` from the beginning each time. That loses the ordering requirement (and costs O(n * m)).
- Forgetting the bounds check and reading `sequence[seqIdx]` after the last element.

## Follow-ups

1. **Many sequences, same array (LeetCode #392 follow-up).** Precompute, for each value, the sorted list of indices where it appears. For each element of a query, binary search for the first index greater than the previous match. Each query costs O(m log n) instead of O(n).
2. **Count how many times `sequence` appears as a subsequence (LeetCode #115).** That is a DP problem: `ways[i][j]` = ways to form `sequence[0..j)` from `array[0..i)`.
3. **Longest common subsequence of two arrays.** See Longest Common Subsequence (hard 16).

## What to remember

"Match in order, gaps allowed" means two pointers moving forward, and the greedy earliest match is provably safe.
