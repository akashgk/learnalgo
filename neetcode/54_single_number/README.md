# Single Number

**Difficulty:** Easy | **Category:** Bit Manipulation | **Pattern:** XOR cancels pairs | **Source:** LeetCode 136; NeetCode 150

## The problem

Every value appears exactly **twice** except one value that appears once. Find it in O(n) time and O(1) extra space.

```
[4, 1, 2, 1, 2]  ->  4
```

## Step 1: The usual tools and why they fall short

- Hash set (add, remove on second sight): O(n) time, **O(n) space**.
- Sort and scan pairs: **O(n log n)**.
- `2 * sum(distinct) - sum(all)`: needs a set of distinct values.

## Step 2: XOR

XOR has exactly the properties needed:

| Property | Meaning |
|---|---|
| `x ^ x = 0` | a pair cancels |
| `x ^ 0 = x` | zero changes nothing |
| commutative and associative | order does not matter |

XOR all the numbers: the pairs cancel wherever they are, and only the single value is left.

```
4 ^ 1 ^ 2 ^ 1 ^ 2 = 4 ^ (1 ^ 1) ^ (2 ^ 2) = 4 ^ 0 ^ 0 = 4
```

## Step 3: The code

<!-- CODE:START -->

Full source: [`single_number.dart`](single_number.dart) (run it with `dart run`).

```dart
// Single Number: every value appears twice except one. Find it in O(n) time and O(1) space.
// XOR everything: x ^ x = 0, x ^ 0 = x, and XOR is commutative, so pairs cancel.

int singleNumber(List<int> nums) => nums.fold(0, (acc, x) => acc ^ x);
```

<!-- CODE:END -->

### Walkthrough

- `fold(0, (acc, x) => acc ^ x)` XORs everything, starting from 0.
- Negative numbers work too: XOR operates on their two's complement bits.

## Step 4: Dry run

`[4, 1, 2, 1, 2]`:

| x | acc (binary) |
|---|---|
| 4 | 100 |
| 1 | 101 |
| 2 | 111 |
| 1 | 110 |
| 2 | 100 = **4** |

## Complexity

- Time: **O(n)**.
- Space: **O(1)**.

## Edge cases

- One element: that element.
- Negative values.

## Common mistakes

- Using a hash map when O(1) space was asked.
- Starting the fold with something other than 0.

## Follow-ups you should be ready for

1. **Single Number II (LeetCode 137): every other value appears three times.** Count each bit mod 3.
2. **Single Number III: two singles.** XOR, split by a differing bit; more_problems 49.
3. **Missing Number.** XOR indices and values; neetcode 58.

## What to remember

XOR cancels equal pairs regardless of order. XOR everything; the unpaired value remains.
