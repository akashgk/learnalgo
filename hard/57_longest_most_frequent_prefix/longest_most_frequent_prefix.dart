// Longest Most Frequent Prefix: among all prefixes, find those shared by the most strings;
// return the longest of them. Trie with pass-through counts.
// O(n * m) time and space (n strings, m = max length).

class _TrieNode {
  final children = <String, _TrieNode>{};
  int count = 0; // number of strings that pass through this node
}

String longestMostFrequentPrefix(List<String> strings) {
  final root = _TrieNode();
  var bestCount = 0;
  var bestPrefix = '';
  for (final s in strings) {
    var node = root;
    for (var i = 0; i < s.length; i++) {
      node = node.children.putIfAbsent(s[i], _TrieNode.new);
      node.count++;
    }
  }
  // Evaluate every prefix once, after all counts are final.
  void visit(_TrieNode node, String prefix) {
    for (final MapEntry(key: ch, value: child) in node.children.entries) {
      final p = prefix + ch;
      if (child.count > bestCount || (child.count == bestCount && p.length > bestPrefix.length)) {
        bestCount = child.count;
        bestPrefix = p;
      }
      visit(child, p);
    }
  }

  visit(root, '');
  return bestPrefix;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(longestMostFrequentPrefix(['algoexpert', 'algorithm', 'frontendexpert', 'mlexpert']), 'algo');
  check(longestMostFrequentPrefix(['cat', 'car', 'cart', 'dog']), 'ca');
  check(longestMostFrequentPrefix(['abc']), 'abc');
  check(longestMostFrequentPrefix(['a', 'b']), 'a'); // tie in count and length: first found
}
