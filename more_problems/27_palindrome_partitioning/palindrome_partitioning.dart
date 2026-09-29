// Palindrome Partitioning: all ways to cut a string into pieces that are all palindromes.
// Backtracking over the end of the next piece, with a precomputed palindrome table.
// O(n * 2^n) time in the worst case ("aaaa..."), O(n^2) space for the table.

List<List<String>> partition(String s) {
  final n = s.length;
  // isPal[i][j]: s[i..j] is a palindrome. Filled from the bottom so isPal[i+1][j-1] is ready.
  final isPal = List.generate(n, (_) => List<bool>.filled(n, false));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = i; j < n; j++) {
      isPal[i][j] = s[i] == s[j] && (j - i < 2 || isPal[i + 1][j - 1]);
    }
  }
  final result = <List<String>>[];
  final path = <String>[];
  void dfs(int start) {
    if (start == n) {
      result.add([...path]);
      return;
    }
    for (var end = start; end < n; end++) {
      if (!isPal[start][end]) continue;
      path.add(s.substring(start, end + 1));
      dfs(end + 1);
      path.removeLast();
    }
  }

  dfs(0);
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(partition('aab'), [
    ['a', 'a', 'b'],
    ['aa', 'b'],
  ]);
  check(partition('a'), [
    ['a'],
  ]);
  check(partition('aba'), [
    ['a', 'b', 'a'],
    ['aba'],
  ]);
  check(partition('aaaa').length, 8); // 2^(n-1): every cut position is independent
}
