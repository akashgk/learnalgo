// Numbers In Pi: split the digits of pi into favorite numbers using the fewest spaces.
// DP over suffixes: minSpaces(i) = min over favorites starting at i of 1 + minSpaces(end).
// O(n^3 + m) time with substring hashing (n = digits of pi, m = total favorite length), O(n + m) space.

int numbersInPi(String pi, List<String> numbers) {
  final favorites = numbers.toSet();
  const inf = 1 << 30;
  // best[i] = min number of pieces to split pi[i..]; best[n] = 0.
  final best = List<int>.filled(pi.length + 1, inf)..[pi.length] = 0;
  for (var i = pi.length - 1; i >= 0; i--) {
    for (var end = i + 1; end <= pi.length; end++) {
      if (best[end] != inf && favorites.contains(pi.substring(i, end)) && best[end] + 1 < best[i]) {
        best[i] = best[end] + 1;
      }
    }
  }
  return best[0] == inf ? -1 : best[0] - 1; // spaces = pieces - 1
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  const pi = '3141592653589793238462643383279';
  check(numbersInPi(pi, ['314159265358979323846', '26433', '8', '3279', '314159265', '35897932384626433832', '79']), 2);
  check(numbersInPi('3141', ['1', '3', '4', '31']), 2); // 31 4 1 or 3 1 4 1 -> min pieces 3
  check(numbersInPi('3141', ['2']), -1);
}
