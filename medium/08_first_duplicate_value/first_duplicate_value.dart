// First Duplicate Value: values are in [1, n]. Return the value whose second occurrence
// has the smallest index, or -1. Mark "seen" by negating array[value - 1].
// O(n) time, O(1) extra space (mutates input; restored before returning).

int firstDuplicateValue(List<int> array) {
  var answer = -1;
  for (final raw in array) {
    final value = raw.abs();
    if (array[value - 1] < 0) {
      answer = value;
      break;
    }
    array[value - 1] *= -1;
  }
  for (var i = 0; i < array.length; i++) {
    array[i] = array[i].abs(); // restore the caller's data
  }
  return answer;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(firstDuplicateValue([2, 1, 5, 2, 3, 3, 4]), 2);
  check(firstDuplicateValue([2, 1, 5, 3, 3, 2, 4]), 3);
  check(firstDuplicateValue([1, 2, 3]), -1);
  final input = [1, 1];
  check(firstDuplicateValue(input), 1);
  check(input, [1, 1]);
}
