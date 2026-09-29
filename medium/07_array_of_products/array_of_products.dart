// Array Of Products: output[i] = product of all elements except array[i], no division.
// Prefix products left-to-right, then multiply by suffix products right-to-left.
// O(n) time, O(n) output, O(1) extra.

List<int> arrayOfProducts(List<int> array) {
  final products = List<int>.filled(array.length, 1);
  var running = 1;
  for (var i = 0; i < array.length; i++) {
    products[i] = running; // product of everything left of i
    running *= array[i];
  }
  running = 1;
  for (var i = array.length - 1; i >= 0; i--) {
    products[i] *= running; // times product of everything right of i
    running *= array[i];
  }
  return products;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(arrayOfProducts([5, 1, 4, 2]), [8, 40, 10, 20]);
  check(arrayOfProducts([1, 8, 6, 2, 4]), [384, 48, 64, 192, 96]);
  check(arrayOfProducts([0, 0, -2, 4, 5]), [0, 0, 0, 0, 0]);
  check(arrayOfProducts([9, 3, 2, 1, 9, 5, 0, 19]), [0, 0, 0, 0, 0, 0, 46170, 0]);
}
