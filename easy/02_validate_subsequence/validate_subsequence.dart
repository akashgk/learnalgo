// Validate Subsequence
// Walk the main array once, advancing a pointer into the sequence on each match.
// O(n) time, O(1) space.

bool isValidSubsequence(List<int> array, List<int> sequence) {
  var seqIdx = 0;
  for (final value in array) {
    if (seqIdx == sequence.length) break;
    if (value == sequence[seqIdx]) seqIdx++;
  }
  return seqIdx == sequence.length;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(isValidSubsequence([5, 1, 22, 25, 6, -1, 8, 10], [1, 6, -1, 10]), true);
  check(isValidSubsequence([5, 1, 22, 25, 6, -1, 8, 10], [1, 6, 10, -1]), false);
  check(isValidSubsequence([1, 1, 6, 1], [1, 1, 1, 6]), false);
  check(isValidSubsequence([5, 1, 22], [5, 1, 22]), true);
  check(isValidSubsequence([1, 2], []), true);
}
