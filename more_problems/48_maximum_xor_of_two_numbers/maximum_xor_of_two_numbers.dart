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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(findMaximumXOR([3, 10, 5, 25, 2, 8]), 28); // 5 ^ 25
  check(findMaximumXOR([14, 70, 53, 83, 49, 91, 36, 80, 92, 51, 66, 70]), 127);
  check(findMaximumXOR([0]), 0);
  check(findMaximumXOR([8, 10, 2]), 10);
}
