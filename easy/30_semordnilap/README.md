# Semordnilap

**Difficulty:** Easy | **Category:** Strings | **Pattern:** Hash set lookup

## Problem
Given a list of unique strings, return all pairs of **different** words that are reverses of each other (for example `diaper` / `repaid`). Each pair should appear once. Palindromes do not pair with themselves.

## Building up the logic
1. Brute force: compare every pair, reversing one. O(n^2 * m).
2. For each word, the only partner it can have is its reverse. Checking "does the reverse exist?" is a hash-set lookup.
3. Avoid double-reporting: remove both words from the set once paired.
4. Skip palindromes explicitly (`reversed != word`).

## Complexity
- Time: O(n * m), where n is the number of words and m the longest word length (reversing and hashing each word costs O(m)).
- Space: O(n * m) for the set.

## Interview notes
- Harder relative: LeetCode #336 (Palindrome Pairs), where concatenations must form palindromes. That one needs a trie or prefix/suffix splitting.
