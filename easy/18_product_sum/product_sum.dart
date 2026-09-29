// Product Sum
// A "special array" contains ints or nested special arrays. Sum of an array at depth d
// is multiplied by d (outermost depth = 1). O(n) time where n counts all elements, O(d) space.

int productSum(List<Object> array, [int depth = 1]) {
  var sum = 0;
  for (final element in array) {
    sum += switch (element) {
      int n => n,
      List<Object> nested => productSum(nested, depth + 1),
      _ => throw ArgumentError('unexpected element $element'),
    };
  }
  return sum * depth;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    productSum([
      5,
      2,
      <Object>[7, -1],
      3,
      <Object>[
        6,
        <Object>[-13, 8],
        4,
      ],
    ]),
    12,
  );
  check(productSum([1, 2, 3]), 6);
  check(productSum([<Object>[<Object>[<Object>[5]]]]), 120); // 5 * 4 * 3 * 2 * 1
}
