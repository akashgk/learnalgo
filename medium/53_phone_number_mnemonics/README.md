# Phone Number Mnemonics

**Difficulty:** Medium | **Category:** Recursion | **Pattern:** Backtracking over fixed-length slots

## The problem

On a phone keypad, digits map to letters:

```
1: 1        2: abc      3: def
4: ghi      5: jkl      6: mno
7: pqrs     8: tuv      9: wxyz
            0: 0
```

(`0` and `1` map to themselves.) Given a string of digits, return every possible **mnemonic**: every string made by replacing each digit with one of its characters. Order does not matter.

```
"1905"  ->  ["1w0j", "1w0k", "1w0l", "1x0j", ..., "1z0l"]   (1 * 4 * 1 * 3 = 12 strings)
```

## Step 1: The structure

The output is the **Cartesian product** of the character lists of each digit. The number of results is the product of the list sizes: at most 4^n.

A decision tree again: level i chooses the character for digit i.

## Step 2: Backtracking

```
build(i):
    if i == n: record current; return
    for each letter of digit i:
        current[i] = letter
        build(i + 1)
```

Because each position has a **fixed slot** in a preallocated array, the "undo" step is free: the next iteration simply overwrites slot i.

## Step 3: Iterative alternative (BFS style)

```
results = [""]
for each digit:
    results = [r + letter for r in results for letter in letters(digit)]
```

Same complexity. Useful if recursion is not allowed.

## Step 4: The code

<!-- CODE:START -->

Full source: [`phone_number_mnemonics.dart`](phone_number_mnemonics.dart) (run it with `dart run`).

```dart
// Phone Number Mnemonics: all letter strings for a digit string ('0' and '1' map to themselves).
// Backtracking over digits. O(4^n * n) time and space.

const _keypad = {
  '0': ['0'],
  '1': ['1'],
  '2': ['a', 'b', 'c'],
  '3': ['d', 'e', 'f'],
  '4': ['g', 'h', 'i'],
  '5': ['j', 'k', 'l'],
  '6': ['m', 'n', 'o'],
  '7': ['p', 'q', 'r', 's'],
  '8': ['t', 'u', 'v'],
  '9': ['w', 'x', 'y', 'z'],
};

List<String> phoneNumberMnemonics(String phoneNumber) {
  final result = <String>[];
  final current = List<String>.filled(phoneNumber.length, '');

  void build(int i) {
    if (i == phoneNumber.length) {
      result.add(current.join());
      return;
    }
    for (final letter in _keypad[phoneNumber[i]]!) {
      current[i] = letter; // overwriting slot i is the "undo"
      build(i + 1);
    }
  }

  build(0);
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `_keypad` is a constant map from digit to its characters.
- `current` is a fixed-size list of slots, one per digit.
- `build(i)` fills slot `i` with each possible letter, then recurses.
- `result.add(current.join());` builds the string only at the leaves.

## Step 5: Dry run for "23" (first results)

| slot 0 | slot 1 | recorded |
|---|---|---|
| a | d | "ad" |
| a | e | "ae" |
| a | f | "af" |
| b | d | "bd" |
| ... | ... | 9 strings total |

## Complexity

- **Time: O(4^n * n)**: up to 4^n results, each built in O(n).
- **Space: O(4^n * n)** for the output; O(n) recursion.

## Common mistakes

- Building strings by concatenation along the recursion and forgetting to restore them.
- Treating `0` and `1` incorrectly (they map to themselves here; LeetCode's version has no 0 or 1).

## Follow-ups

1. **Letter Combinations of a Phone Number (LeetCode #17):** identical except for 0 and 1.
2. **Only return mnemonics that are real words:** filter with a dictionary, or better, prune with a trie while building (see Boggle Board, hard 30).

## What to remember

Cartesian products are backtracking with one slot per position. Fixed slots make the undo step automatic.
