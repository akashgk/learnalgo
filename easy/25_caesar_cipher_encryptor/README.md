# Caesar Cipher Encryptor

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Modular arithmetic on character codes

## Problem
Given a string of lowercase letters and a non-negative integer key, shift every letter forward by `key` positions in the alphabet, wrapping around (`z` shifted by 1 is `a`). Return the new string.

## Building up the logic
1. Map each letter to 0..25 (`c - 'a'`), add the key, take `% 26`, map back.
2. Reduce the key with `key % 26` first. A key of 54 is the same as 2. Forgetting this is the classic bug when you try to handle wrap-around with a single `if`.
3. Build the output in one go (list of code units then one `String.fromCharCodes`). Repeated string concatenation in a loop is O(n^2) in many languages.

## Complexity
- Time: O(n).
- Space: O(n) for the result.

## Interview notes
- Negative keys (decrypt): `((c - a + shift) % 26 + 26) % 26` in Java/C++, where `%` can be negative. Dart's `%` always returns a non-negative result for a positive divisor, so it is safe here.
