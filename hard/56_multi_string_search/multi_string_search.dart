// Multi String Search: for each small string, is it contained in the big string?
// Trie of small strings; walk the trie from every start index of the big string.
// O(ns + b * s) time, O(ns) space (n small strings of max length s, big string length b).

class _TrieNode {
  final children = <String, _TrieNode>{};
  int? wordIndex; // index into smallStrings if a word ends here
}

List<bool> multiStringSearch(String bigString, List<String> smallStrings) {
  final root = _TrieNode();
  for (var i = 0; i < smallStrings.length; i++) {
    var node = root;
    for (final ch in smallStrings[i].split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.wordIndex = i;
  }
  final found = List<bool>.filled(smallStrings.length, false);
  for (var start = 0; start < bigString.length; start++) {
    var node = root;
    for (var j = start; j < bigString.length; j++) {
      final next = node.children[bigString[j]];
      if (next == null) break; // no small string continues this way
      node = next;
      if (node.wordIndex != null) found[node.wordIndex!] = true;
    }
  }
  return found;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    multiStringSearch('this is a big string', ['this', 'yo', 'is', 'a', 'bigger', 'string', 'kappa']),
    [true, false, true, true, false, true, false],
  );
  check(multiStringSearch('abcdefghijklmnopqrstuvwxyz', ['abc', 'mnopqr', 'wyz', 'no', 'e', 'tuuv']), [true, true, false, true, true, false]);
}
