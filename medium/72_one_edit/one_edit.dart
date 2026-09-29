// One Edit: are two strings at most one insert/delete/replace apart?
// Walk both with two pointers; on the first mismatch, skip according to the length difference.
// O(n) time, O(1) space.

bool oneEdit(String stringOne, String stringTwo) {
  final (a, b) = stringOne.length >= stringTwo.length ? (stringOne, stringTwo) : (stringTwo, stringOne);
  if (a.length - b.length > 1) return false;
  var i = 0, j = 0;
  var edited = false;
  while (i < a.length && j < b.length) {
    if (a[i] != b[j]) {
      if (edited) return false;
      edited = true;
      if (a.length == b.length) j++; // replace: advance both; otherwise delete from longer
    } else {
      j++;
    }
    i++;
  }
  return true;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(oneEdit('hello', 'hollo'), true); // replace
  check(oneEdit('hello', 'helo'), true); // delete
  check(oneEdit('a', 'ab'), true); // insert at end
  check(oneEdit('abc', 'cba'), false);
  check(oneEdit('same', 'same'), true);
  check(oneEdit('ab', 'abcd'), false);
  check(oneEdit('xabc', 'abc'), true);
}
