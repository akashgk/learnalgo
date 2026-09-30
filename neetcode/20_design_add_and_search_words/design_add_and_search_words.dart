// Design Add and Search Words Data Structure: addWord(word), search(pattern) where '.' matches any
// one letter. Trie + DFS that branches into every child on '.'.
// addWord O(L); search O(L) without dots, up to O(26^d * L) with d dots in the worst case.

class _TrieNode {
  final children = <String, _TrieNode>{};
  bool isWord = false;
}

class WordDictionary {
  final _root = _TrieNode();

  void addWord(String word) {
    var node = _root;
    for (final ch in word.split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.isWord = true;
  }

  bool search(String word) {
    bool dfs(_TrieNode node, int i) {
      if (i == word.length) return node.isWord;
      final ch = word[i];
      if (ch == '.') {
        // Wildcard: any child may continue the match.
        for (final child in node.children.values) {
          if (dfs(child, i + 1)) return true;
        }
        return false;
      }
      final next = node.children[ch];
      return next != null && dfs(next, i + 1);
    }

    return dfs(_root, 0);
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final d = WordDictionary()
    ..addWord('bad')
    ..addWord('dad')
    ..addWord('mad');
  check(d.search('pad'), false);
  check(d.search('bad'), true);
  check(d.search('.ad'), true);
  check(d.search('b..'), true);
  check(d.search('b.'), false); // length must match exactly
  check(d.search('...'), true);
  check(d.search('....'), false);
}
