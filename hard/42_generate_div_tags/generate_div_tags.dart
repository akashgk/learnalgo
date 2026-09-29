// Generate Div Tags: all valid (properly nested) strings of n "<div>" and n "</div>" tags.
// Backtracking with counts of remaining opens and closes. O(C(n) * n) time and space,
// where C(n) is the nth Catalan number.

List<String> generateDivTags(int numberOfTags) {
  final result = <String>[];
  final current = <String>[];

  void build(int opensLeft, int closesLeft) {
    if (opensLeft == 0 && closesLeft == 0) {
      result.add(current.join());
      return;
    }
    if (opensLeft > 0) {
      current.add('<div>');
      build(opensLeft - 1, closesLeft);
      current.removeLast();
    }
    if (closesLeft > opensLeft) {
      // can only close a tag that is currently open
      current.add('</div>');
      build(opensLeft, closesLeft - 1);
      current.removeLast();
    }
  }

  build(numberOfTags, numberOfTags);
  return result;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(generateDivTags(2), ['<div><div></div></div>', '<div></div><div></div>']);
  check(generateDivTags(3).length, 5);
  check(generateDivTags(5).length, 42);
}
