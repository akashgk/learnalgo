// Suffix Trie Construction: trie of all suffixes, each terminated by '*'.
// Build O(n^2) time and space; contains(s) O(m).

class SuffixTrie {
  SuffixTrie(String string) {
    for (var i = 0; i < string.length; i++) {
      _insertSubstringStartingAt(string, i);
    }
  }

  final root = <String, Object>{};
  static const endSymbol = '*';

  void _insertSubstringStartingAt(String string, int start) {
    var node = root;
    for (var j = start; j < string.length; j++) {
      node = node.putIfAbsent(string[j], () => <String, Object>{}) as Map<String, Object>;
    }
    node[endSymbol] = true;
  }

  /// True if [string] is a suffix (not merely a substring) of the original string.
  bool contains(String string) {
    var node = root;
    for (final ch in string.split('')) {
      final next = node[ch];
      if (next == null) return false;
      node = next as Map<String, Object>;
    }
    return node.containsKey(endSymbol);
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final trie = SuffixTrie('babc');
  check(trie.contains('abc'), true);
  check(trie.contains('babc'), true);
  check(trie.contains('c'), true);
  check(trie.contains('ab'), false); // substring but not a suffix
  check(trie.contains('x'), false);
  check((trie.root['b']! as Map<String, Object>).keys.toList()..sort(), ['a', 'c']);
}
