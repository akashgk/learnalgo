// Boggle Board: which words can be formed by paths of adjacent cells (8 directions),
// using each cell at most once per word? Build a trie of words, DFS from every cell.
// O(w * h * 8^s + total word length) time, O(total word length + w * h) space.

class _TrieNode {
  final children = <String, _TrieNode>{};
  String? word; // set on the node where a word ends
}

List<String> boggleBoard(List<List<String>> board, List<String> words) {
  final root = _TrieNode();
  for (final w in words) {
    var node = root;
    for (final ch in w.split('')) {
      node = node.children.putIfAbsent(ch, _TrieNode.new);
    }
    node.word = w;
  }
  final rows = board.length, cols = board[0].length;
  final visited = List.generate(rows, (_) => List<bool>.filled(cols, false));
  final found = <String>{};

  void explore(int r, int c, _TrieNode parent) {
    if (r < 0 || r >= rows || c < 0 || c >= cols || visited[r][c]) return;
    final node = parent.children[board[r][c]];
    if (node == null) return; // no word continues with this prefix: prune
    if (node.word != null) found.add(node.word!);
    visited[r][c] = true;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr != 0 || dc != 0) explore(r + dr, c + dc, node);
      }
    }
    visited[r][c] = false; // backtrack so other paths can use this cell
  }

  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < cols; c++) {
      explore(r, c, root);
    }
  }
  return [for (final w in words) if (found.contains(w)) w];
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final board = [
    't h i s i s a'.split(' '),
    's i m p l e x'.split(' '),
    'b x x x x e b'.split(' '),
    'x o g g l x o'.split(' '),
    'x x x D T r a'.split(' '),
    'R E P E A d x'.split(' '),
    'x x x x x x x'.split(' '),
    'N O T R E - P'.split(' '),
    'x x D E T A E'.split(' '),
  ];
  final words = ['this', 'is', 'not', 'a', 'simple', 'boggle', 'board', 'test', 'REPEATED', 'NOTRE-PEATED'];
  check(boggleBoard(board, words), ['this', 'is', 'a', 'simple', 'boggle', 'board', 'NOTRE-PEATED']);
  check(boggleBoard([['a', 'b'], ['c', 'd']], ['abdc', 'aa', 'acdb']), ['abdc', 'acdb']);
}
