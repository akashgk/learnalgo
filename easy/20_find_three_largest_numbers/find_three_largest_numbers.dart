// Find Three Largest Numbers without sorting the input. Single pass, shifting a 3-slot window.
// O(n) time, O(1) space. Returns them in ascending order, duplicates allowed.

List<int> findThreeLargestNumbers(List<int> array) {
  final top = List<int?>.filled(3, null); // top[2] is the largest
  for (final x in array) {
    // Find the highest slot x beats, then shift smaller slots down.
    for (var i = 2; i >= 0; i--) {
      if (top[i] == null || x > top[i]!) {
        for (var j = 0; j < i; j++) {
          top[j] = top[j + 1];
        }
        top[i] = x;
        break;
      }
    }
  }
  return top.whereType<int>().toList();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(findThreeLargestNumbers([141, 1, 17, -7, -17, -27, 18, 541, 8, 7, 7]), [18, 141, 541]);
  check(findThreeLargestNumbers([10, 5, 9, 10, 12]), [10, 10, 12]);
  check(findThreeLargestNumbers([-1, -2, -3, -7, -17]), [-3, -2, -1]);
}
