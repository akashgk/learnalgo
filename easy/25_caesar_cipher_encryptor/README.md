# Caesar Cipher Encryptor

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Modular arithmetic on character codes

## The problem

Given a non-empty string of lowercase letters and a non-negative integer `key`, shift every letter forward by `key` positions in the alphabet, wrapping around from `z` to `a`. Return the encrypted string.

```
"xyz", key 2   ->  "zab"
"abc", key 52  ->  "abc"   (52 = two full trips around the alphabet)
"abc", key 57  ->  "fgh"   (57 = 52 + 5)
```

## Step 1: Work an example by hand

Map letters to numbers: `a = 0, b = 1, ..., z = 25`. Shifting `x` (23) by 2 gives 25, which is `z`. Shifting `y` (24) by 2 gives 26, which does not exist; wrapping around means 26 becomes 0 (`a`). Shifting `z` (25) by 2 gives 27, which becomes 1 (`b`).

"Wrap around after 26" is exactly what the remainder operator does: `(23 + 2) % 26 = 25`, `(24 + 2) % 26 = 0`, `(25 + 2) % 26 = 1`.

## Step 2: The formula

```
newLetter = (letter - 'a' + key) % 26 + 'a'
```

1. `letter - 'a'` converts the character code to 0..25.
2. `+ key` shifts.
3. `% 26` wraps.
4. `+ 'a'` converts back to a character code.

Reduce the key first with `key % 26`. A key of 1,000,002 behaves like 2. Without this, a fix like "if the result is past `z`, subtract 26" works only for keys below 26: the classic bug.

## Step 3: The code

<!-- CODE:START -->

Full source: [`caesar_cipher_encryptor.dart`](caesar_cipher_encryptor.dart) (run it with `dart run`).

```dart
// Caesar Cipher Encryptor: shift lowercase letters by key, wrapping z -> a.
// O(n) time, O(n) space for the output.

String caesarCipherEncryptor(String string, int key) {
  const a = 97; // 'a'
  final shift = key % 26; // large keys wrap around
  return String.fromCharCodes(string.codeUnits.map((c) => a + (c - a + shift) % 26));
}
```

<!-- CODE:END -->

### Walkthrough

- `const a = 97;` is the character code of `'a'`, named for readability.
- `final shift = key % 26;` normalizes large keys.
- `string.codeUnits.map((c) => a + (c - a + shift) % 26)` applies the formula to every character code.
- `String.fromCharCodes(...)` builds the result string once. Building it with `+=` in a loop would copy the partial string each time (O(n^2)).

## Step 4: Dry run

`"xyz"`, key 2 (shift 2):

| char | code - 97 | + 2 | % 26 | result char |
|---|---|---|---|---|
| x | 23 | 25 | 25 | z |
| y | 24 | 26 | 0 | a |
| z | 25 | 27 | 1 | b |

Result: `"zab"`.

## Complexity

- **Time: O(n)**.
- **Space: O(n)** for the new string (strings are immutable in Dart, so the output needs its own storage).

## Common mistakes

- Not reducing the key: `if (x > 122) x -= 26` only works for keys up to 25.
- Negative keys (decryption) in Java or C++: `-3 % 26` is `-3` there. Use `((x % 26) + 26) % 26`. In Dart, `%` with a positive divisor always returns a non-negative result, so `-3 % 26 == 23`.
- Forgetting non-lowercase characters if the problem allows them (not here).

## Follow-ups

1. **Decrypt:** shift by `-key` (or `26 - key % 26`).
2. **Uppercase and non-letters:** apply the formula separately with base `'A'`, leave other characters unchanged.
3. **Break the cipher without the key:** try all 26 shifts and score each result by English letter frequencies.

## What to remember

Anything that "wraps around" is modular arithmetic. Normalize to a 0-based range, apply `% size`, convert back.
