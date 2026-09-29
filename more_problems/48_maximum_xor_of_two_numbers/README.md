# Maximum XOR of Two Numbers in an Array

**Difficulty:** Hard | **Category:** Tries / Bit manipulation | **Pattern:** Binary trie with greedy opposite-bit walk | **Source:** LeetCode 421; Striver A2Z

## The problem

Given non-negative integers (below 2^31), return the maximum of `nums[i] ^ nums[j]`.

```
[3, 10, 5, 25, 2, 8]  ->  28      (5 ^ 25)
```

## Step 1: Brute force

All pairs: O(n^2). With n = 2 * 10^5, that is 4 * 10^10 operations. Too slow.

## Step 2: Greedy by bits

A number is maximized by making its **highest** bit 1 whenever possible: bit 30 set is worth more than all lower bits combined (2^30 > 2^30 - 1). So to maximize `x ^ y` for a fixed `x`, choose `y` bit by bit from the top: at each bit, prefer `y`'s bit to be the **opposite** of `x`'s (that makes the XOR bit 1), if any candidate with the current prefix allows it.

We need a structure that answers "among numbers whose top bits match the path chosen so far, is there one whose next bit is b?" That is a **binary trie**: each level is a bit (most significant first), each node has children 0 and 1.

## Step 3: The algorithm

For each `x`:

1. Insert `x` into the trie (31 levels).
2. Walk the trie from the root. At bit `b`, let `want = (bit b of x) ^ 1`. If the child `want` exists, go there and set bit `b` of the result. Otherwise go to the other child (it exists, since the trie contains at least `x` itself).

The best result over all `x` is the answer. Because every pair is considered when its later element is processed, inserting before querying is enough (and querying `x` against itself gives 0, harmless).

## Step 4: The code

<!-- CODE:START -->

Full source: [`maximum_xor_of_two_numbers.dart`](maximum_xor_of_two_numbers.dart) (run it with `dart run`).

```dart
// Maximum XOR of Two Numbers in an Array (non-negative ints below 2^31).
// Binary trie of the numbers' bits, most significant first. For each number, walk the trie
// preferring the opposite bit at every level. O(n * 31) time, O(n * 31) space.

class _TrieNode {
  final children = List<_TrieNode?>.filled(2, null);
}

const _bits = 31;

int findMaximumXOR(List<int> nums) {
  final root = _TrieNode();
  var best = 0;
  for (final x in nums) {
    // Insert x.
    var node = root;
    for (var b = _bits - 1; b >= 0; b--) {
      final bit = (x >> b) & 1;
      node = node.children[bit] ??= _TrieNode();
    }
    // Query: best partner for x among the numbers inserted so far (including x itself, XOR 0).
    node = root;
    var xor = 0;
    for (var b = _bits - 1; b >= 0; b--) {
      final want = ((x >> b) & 1) ^ 1; // the opposite bit makes this bit of the XOR 1
      if (node.children[want] != null) {
        xor |= 1 << b;
        node = node.children[want]!;
      } else {
        node = node.children[want ^ 1]!;
      }
    }
    if (xor > best) best = xor;
  }
  return best;
}
```

<!-- CODE:END -->

### Walkthrough

- `_TrieNode` has two child slots.
- `node.children[bit] ??= _TrieNode()` creates the child if missing and moves to it.
- In the query, `xor |= 1 << b` records a 1 in the result whenever the opposite bit exists.
- The fallback `node.children[want ^ 1]!` is safe: some number (at least `x`) passed through this node.

## Step 5: Dry run

Only the low 5 bits matter (all numbers are below 32). When `x = 25 = 11001` is processed, the trie holds `3 = 00011`, `10 = 01010`, `5 = 00101` and `25` itself.

| bit | x's bit | want | exists? | path so far | xor bit |
|---|---|---|---|---|---|
| 4 | 1 | 0 | yes (3, 10, 5) | 0 | 1 |
| 3 | 1 | 0 | yes (3, 5) | 00 | 1 |
| 2 | 0 | 1 | yes (5) | 001 | 1 |
| 1 | 0 | 1 | no (5 has 0) | 0010 | 0 |
| 0 | 1 | 0 | no (5 has 1) | 00101 | 0 |

The walk ends at 5, with XOR `11100 = 28`.

## Complexity

- Time: **O(n * B)**, B = 31 bits.
- Space: **O(n * B)** trie nodes in the worst case.

## Edge cases

- One number: 0.
- All equal: 0.
- Numbers with different bit lengths: all are stored with 31 bits (leading zeros), so levels line up.

## Common mistakes

- Inserting bits from least significant to most significant (the greedy must decide the highest bit first).
- Not padding to a fixed number of bits.
- Querying an empty trie (insert first).

## Follow-ups you should be ready for

1. **Prefix-set alternative.** Build the answer bit by bit from the top: at each step, guess the next bit is 1 and check with a hash set of prefixes whether two prefixes XOR to the guess. Also O(n * B).
2. **Maximum XOR With an Element From Array (LeetCode 1707).** Queries with a limit: sort queries and numbers, insert numbers up to each limit (offline processing).
3. **Maximum subarray XOR.** Insert prefix XORs into the trie; the best `prefix[j] ^ prefix[i]` is the answer.

## What to remember

To maximize XOR, decide bits from the top and try to make each one differ. A binary trie over the numbers' bits answers "can this bit differ?" in O(1) per level.
