# Plus One

**Difficulty:** Easy | **Category:** Math & Geometry | **Pattern:** Carry propagation from the right | **Source:** LeetCode 66; NeetCode 150

## The problem

A non-negative integer is stored as a list of digits, most significant first, with no leading zeros. Return the digits of that number plus one.

```
[1, 2, 3]  ->  [1, 2, 4]
[1, 9, 9]  ->  [2, 0, 0]
[9, 9, 9]  ->  [1, 0, 0, 0]
```

## Step 1: Why not convert to an integer?

The list can be longer than any fixed-width integer (100 digits). Converting would overflow in most languages. Do the arithmetic on the digits, as on paper.

## Step 2: Carry

Walk from the rightmost digit:

- a digit **below 9**: add 1, done (no carry continues);
- a **9**: becomes 0, and the carry moves one position left.

If the carry passes the leftmost digit, every digit was 9: the result is 1 followed by zeros (one digit longer).

## Step 3: The code

<!-- CODE:START -->

Full source: [`plus_one.dart`](plus_one.dart) (run it with `dart run`).

```dart
// Plus One: a non-negative integer is stored as a list of digits (most significant first).
// Add one. Walk from the right: a digit below 9 absorbs the carry and we stop; a 9 becomes 0 and
// the carry moves left. All 9s grow the number by one digit. O(n) time.

List<int> plusOne(List<int> digits) {
  final result = [...digits];
  for (var i = result.length - 1; i >= 0; i--) {
    if (result[i] < 9) {
      result[i]++;
      return result; // no carry left
    }
    result[i] = 0; // 9 + 1 = 10: write 0, carry 1
  }
  return [1, ...result]; // every digit was 9, e.g. 999 -> 1000
}
```

<!-- CODE:END -->

### Walkthrough

- The input is copied so it is not modified.
- The early `return` fires at the first digit that absorbs the carry.
- `[1, ...result]` prepends the new leading 1 when every digit was 9.

## Step 4: Dry run

`[1, 9, 9]`:

| i | digit | action | result |
|---|---|---|---|
| 2 | 9 | set 0, carry | [1, 9, 0] |
| 1 | 9 | set 0, carry | [1, 0, 0] |
| 0 | 1 | 1 + 1 = 2, stop | [2, 0, 0] |

## Complexity

- Time: **O(n)** worst case (all 9s); O(1) on average for random digits.
- Space: **O(n)** for the result.

## Edge cases

- `[0]`: `[1]`.
- All 9s: one digit longer.

## Common mistakes

- Converting to an integer.
- Forgetting the all-9s case.

## Follow-ups you should be ready for

1. **Add two numbers given as digit lists (LeetCode 989, 415).** The same carry loop over two lists.
2. **Linked list version (LeetCode 369).** Reverse, add, reverse; or find the rightmost non-9 node.
3. **Multiply Strings.** neetcode 52.

## What to remember

Carry propagation stops at the first digit that is not 9. All 9s means the number grows by one digit.
