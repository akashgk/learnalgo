// Plus One: a non-negative integer is stored as a list of digits (most significant first).
// Add one. Walk from the right: a digit below 9 absorbs the carry and we stop; a 9 becomes 0 and
// the carry moves left. All 9s grow the number by one digit. O(n) time.

List<int> plusOne(List<int> digits) {
  final result = [...digits];
  for (var i = result.length - 1; i >= 0; i--) {
    if (result[i] < 9) {
      result[i]++;
      return result; // no carry left
    }
    result[i] = 0; // 9 + 1 = 10: write 0, carry 1
  }
  return [1, ...result]; // every digit was 9, e.g. 999 -> 1000
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(plusOne([1, 2, 3]), [1, 2, 4]);
  check(plusOne([4, 3, 2, 1]), [4, 3, 2, 2]);
  check(plusOne([9]), [1, 0]);
  check(plusOne([1, 9, 9]), [2, 0, 0]);
  check(plusOne([9, 9, 9]), [1, 0, 0, 0]);
}
