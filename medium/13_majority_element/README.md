# Majority Element

**Difficulty:** Medium | **Category:** Arrays | **Pattern:** Boyer-Moore majority vote

## Problem
Given a non-empty integer array that is guaranteed to contain a majority element (one appearing in more than half the positions), return it. Target O(n) time and O(1) space.

## Building up the logic
1. Hash map of counts: O(n) time, O(n) space.
2. Sort and take the middle element: O(n log n). The middle must be the majority because it occupies more than half the positions.
3. **Boyer-Moore voting:** pair each occurrence of the majority with a different element and cancel both. Since the majority has more than half of all elements, it cannot be fully cancelled.
4. Implementation: keep a `candidate` and a `count`. Same as candidate: `count++`; different: `count--`; when `count` hits 0, adopt the next element as candidate.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- If a majority is **not** guaranteed, add a second pass that counts the candidate and checks `count > n / 2`.
- Generalization: elements appearing more than n/3 times (LeetCode #229) keep two candidates. More than n/k: keep k - 1 candidates (Misra-Gries). This matters in streaming systems and is a good depth signal in Google interviews.
- Bit-by-bit alternative: for each of the 32/64 bits, the majority's bit equals the majority bit value across the array.
