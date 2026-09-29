# Best Digits

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Monotonic stack (greedy digit removal)

## The problem

Given a string of digits and an integer `numDigits`, remove exactly `numDigits` digits (keeping the others in their original order) so that the remaining number is as **large** as possible. Return it as a string.

```
number = "462839", numDigits = 2  ->  "6839"
number = "54321",  numDigits = 2  ->  "543"
```

## Step 1: Work an example by hand

`"462839"`, remove 2. The first digit of the result matters most. Can we make it bigger than 4? The 6 right after it is bigger: remove the 4, and the number starts with 6. That is clearly better than anything starting with 4.

Now `"62839"`, one removal left. 6 vs 2: keep 6 (removing it would put 2 first). 2 vs 8: 8 is bigger and comes right after, so remove the 2: `"6839"`. No removals left.

**Rule:** scanning left to right, whenever a digit is followed by a **bigger** digit, removing the smaller one makes the number bigger, because it lets a bigger digit move into a more significant position.

## Step 2: Brute force

Try all `C(n, k)` ways to remove k digits and take the largest result. Exponential.

## Step 3: Greedy with a stack

Scan digits left to right, keeping the result so far on a stack:

- While removals remain and the stack top is **smaller** than the incoming digit, pop the top (remove it).
- Push the incoming digit.

After the scan the stack is **non-increasing**. If removals are still owed (for example `"54321"` never triggers a pop), remove from the **end**: the smallest digits sit at the end of a non-increasing sequence, and removing trailing digits hurts least.

**Why greedy is safe:** at any point, a smaller digit followed by a bigger one should be removed: keeping it means a smaller digit occupies a more significant position than necessary, and nothing later can compensate for a smaller digit in a more significant position.

## Step 4: The code

<!-- CODE:START -->

Full source: [`best_digits.dart`](best_digits.dart) (run it with `dart run`).

```dart
// Best Digits: remove exactly numDigits digits to make the largest possible number.
// Monotonic (non-increasing) stack: pop smaller digits while removals remain.
// O(n) time, O(n) space.

String bestDigits(String number, int numDigits) {
  final stack = <int>[];
  var toRemove = numDigits;
  for (final d in number.codeUnits) {
    while (toRemove > 0 && stack.isNotEmpty && stack.last < d) {
      stack.removeLast(); // a bigger digit arriving later beats a smaller digit earlier
      toRemove--;
    }
    stack.add(d);
  }
  // Still owe removals: the stack is non-increasing, so drop from the end (smallest).
  stack.length -= toRemove;
  return String.fromCharCodes(stack);
}
```

<!-- CODE:END -->

### Walkthrough

- `stack` holds character codes (comparing codes `'0'..'9'` compares digit values).
- The `while` loop pops smaller digits while removals remain.
- `stack.length -= toRemove;` truncates the end for any removals still owed.
- `String.fromCharCodes(stack)` builds the result.

## Step 5: Dry run

`"462839"`, remove 2:

| digit | pops | stack after | removals left |
|---|---|---|---|
| 4 | | 4 | 2 |
| 6 | 4 (4 < 6) | 6 | 1 |
| 2 | | 6 2 | 1 |
| 8 | 2 (2 < 8) | 6 8 | 0 |
| 3 | (no removals left) | 6 8 3 | 0 |
| 9 | (no removals left) | 6 8 3 9 | 0 |

Result `"6839"`.

## Complexity

- **Time: O(n)**: each digit is pushed once and popped at most once.
- **Space: O(n)**.

## Common mistakes

- Forgetting the leftover removals at the end (`"54321"`).
- Popping when the top is **equal** (unnecessary; it does not make the number bigger).

## Follow-ups

1. **Remove K Digits (LeetCode #402):** the **smallest** number instead: pop while the top is **larger**, then strip leading zeros (and return `"0"` if empty).
2. **Remove Duplicate Letters (#316):** smallest lexicographic result using each letter once; same stack plus "can I pop it? only if it appears later".
3. **Create Maximum Number (#321):** combine this with merging two sequences.

## What to remember

To build the largest (or smallest) subsequence of fixed length, scan with a monotonic stack and pop whenever a better digit arrives and you still can.
