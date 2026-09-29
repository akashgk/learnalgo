// Powerset: all subsets. Iterative doubling: for each element, add it to every existing subset.
// O(n * 2^n) time and space.

List<List<int>> powerset(List<int> array) {
  final subsets = <List<int>>[[]];
  for (final x in array) {
    final count = subsets.length; // snapshot: only extend subsets that existed before x
    for (var i = 0; i < count; i++) {
      subsets.add([...subsets[i], x]);
    }
  }
  return subsets;
}

/// Bitmask version: subset `mask` contains array[i] iff bit i is set.
List<List<int>> powersetBitmask(List<int> array) => [
      for (var mask = 0; mask < 1 << array.length; mask++)
        [for (var i = 0; i < array.length; i++) if (mask & (1 << i) != 0) array[i]],
    ];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(powerset([1, 2, 3]), [<int>[], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3]]);
  check(powersetBitmask([1, 2, 3]), [<int>[], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3]]);
  check(powerset([]), [<int>[]]);
}
