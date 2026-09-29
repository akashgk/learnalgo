// Strings Made Up Of Strings: which strings can be formed by concatenating substrings from the
// given list (each substring may be reused)? Trie of substrings + DP (word break) per string.
// O(sum over strings of m * L) time with a trie (m = string length, L = max substring length),
// O(total substring length) space.

class _TrieNode {
  final children = <int, _TrieNode>{};
  bool isEnd = false;
}

List<String> stringsMadeUpOfStrings(List<String> strings, List<String> substrings) {
  final root = _TrieNode();
  for (final s in substrings) {
    var node = root;
    for (final c in s.codeUnits) {
      node = node.children.putIfAbsent(c, _TrieNode.new);
    }
    node.isEnd = true;
  }

  bool canBuild(String s) {
    // ok[i] = s[0..i) can be built. Walk the trie forward from every reachable position.
    final ok = List<bool>.filled(s.length + 1, false)..[0] = true;
    for (var start = 0; start < s.length; start++) {
      if (!ok[start]) continue;
      var node = root;
      for (var k = start; k < s.length; k++) {
        final next = node.children[s.codeUnitAt(k)];
        if (next == null) break;
        node = next;
        if (node.isEnd) ok[k + 1] = true;
      }
    }
    return ok[s.length];
  }

  return [
    for (final s in strings)
      if (s.isNotEmpty && canBuild(s)) s,
  ];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(stringsMadeUpOfStrings(['bar', 'are', 'foo', 'ba', 'b', 'barely'], ['b', 'a', 'r', 'ba', 'ar', 'bar', 'ely']), [
    'bar',
    'ba',
    'b',
    'barely',
  ]);
  check(stringsMadeUpOfStrings(['aaaa'], ['aa']), ['aaaa']);
  check(stringsMadeUpOfStrings(['abc'], ['ab', 'bc']), []);
}
