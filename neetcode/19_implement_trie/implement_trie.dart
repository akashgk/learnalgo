// Implement Trie (Prefix Tree): insert(word), search(word), startsWith(prefix).
// Each node maps a character to a child and marks whether a word ends there.
// Every operation is O(L) for a word or prefix of length L.

class _TrieNode {
  final children = <String, _TrieNode>{};
  bool isWord = false;
}

class Trie {
  final _root = _TrieNode();

  void insert(String word) {
    var node = _root;
    for (final ch in word.split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.isWord = true; // the path alone is not enough: "app" is a prefix of "apple"
  }

  bool search(String word) => _walk(word)?.isWord ?? false;

  bool startsWith(String prefix) => _walk(prefix) != null;

  /// Follows [s] from the root; null if the path breaks.
  _TrieNode? _walk(String s) {
    _TrieNode? node = _root;
    for (final ch in s.split('')) {
      node = node!.children[ch];
      if (node == null) return null;
    }
    return node;
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final trie = Trie()..insert('apple');
  check(trie.search('apple'), true);
  check(trie.search('app'), false); // a prefix, not an inserted word
  check(trie.startsWith('app'), true);
  trie.insert('app');
  check(trie.search('app'), true);
  check(trie.startsWith('b'), false);
  check(trie.startsWith(''), true);
}
