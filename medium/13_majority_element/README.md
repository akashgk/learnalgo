# Majority Element

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Boyer-Moore majority vote

## The problem

Given a non-empty array of integers that is **guaranteed** to contain a majority element (a value that appears in more than half of the positions), return that element. Aim for O(n) time and O(1) space.

```
[1, 2, 3, 2, 2, 1, 2]        ->  2   (4 of 7)
[5, 4, 3, 2, 1, 1, 1, 1, 1]  ->  1   (5 of 9)
```

## Step 1: Work an example by hand

Imagine an election where each voter holds a sign. Pair up voters holding **different** signs and send each pair home. Keep doing that. The majority has more voters than everyone else combined, so even if every other voter pairs off against a majority voter, some majority voters remain. The last people standing all hold the majority's sign.

## Step 2: Straightforward approaches

1. **Count with a hash map**, return the value with count > n/2: O(n) time, O(n) space.
2. **Sort** and return the middle element: O(n log n). The majority occupies more than half of the sorted array, so it must cover the middle position.

Both are fine answers; the interviewer will ask for O(1) space.

## Step 3: Boyer-Moore voting

Scan once, keeping a `candidate` and a `count`:

- If `count == 0`, adopt the current element as the new candidate.
- If the element equals the candidate, `count++`; otherwise `count--` (this is "pairing off" two different values).

At the end, the candidate is the majority.

**Why it works:** each decrement cancels one candidate occurrence against one different element. Cancellations remove pairs of **distinct** values. Since the majority has more than n/2 occurrences, it cannot be fully cancelled: every cancellation of a majority occurrence uses up a non-majority element, and there are fewer of those. Whatever survives at the end must be the majority.

## Step 4: The code

<!-- CODE:START -->

Full source: [`majority_element.dart`](majority_element.dart) (run it with `dart run`).

```dart
// Majority Element (guaranteed to exist: appears more than n/2 times).
// Boyer-Moore voting. O(n) time, O(1) space.

int majorityElement(List<int> array) {
  var candidate = 0, count = 0;
  for (final x in array) {
    if (count == 0) candidate = x;
    count += x == candidate ? 1 : -1;
  }
  return candidate;
}
```

<!-- CODE:END -->

### Walkthrough

- `var candidate = 0, count = 0;` starts empty (the first element becomes the candidate because `count == 0`).
- `if (count == 0) candidate = x;` starts a new "segment" with `x` as its leader.
- `count += x == candidate ? 1 : -1;` votes for or against the candidate.

## Step 5: Dry run

`[1, 2, 3, 2, 2, 1, 2]`:

| x | count == 0? | candidate | count after |
|---|---|---|---|
| 1 | yes | 1 | 1 |
| 2 | no | 1 | 0 |
| 3 | yes | 3 | 1 |
| 2 | no | 3 | 0 |
| 2 | yes | 2 | 1 |
| 1 | no | 2 | 0 |
| 2 | yes | 2 | 1 |

Result: 2.

## Complexity

- **Time: O(n)**, one pass.
- **Space: O(1)**.

## Important caveat

The algorithm **always** returns some candidate, even if no majority exists (`[1, 2, 3]` returns 3). It is only correct because a majority is guaranteed. Without that guarantee, add a second pass that counts the candidate and checks `count > n / 2`.

## Common mistakes

- Resetting the candidate when count becomes 0 but forgetting to count the new element itself.
- Skipping the verification pass when the majority is not guaranteed.

## Follow-ups

1. **Majority Element II (LeetCode #229):** all elements appearing more than n/3 times. At most two such elements exist; keep **two** candidates and two counters, then verify both.
2. **More than n/k times:** keep k - 1 candidates (Misra-Gries summary). This is used in streaming systems to find "heavy hitters" with limited memory; mentioning it is a plus at Google.
3. **Bit counting alternative:** for each bit position, the majority's bit equals the majority bit value across all numbers. O(32 n).

## What to remember

Cancel pairs of different values; the majority cannot be cancelled away. Verify if a majority is not guaranteed.
