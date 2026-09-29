// Smallest Substring Containing: shortest substring of bigString containing every character of
// smallString (with multiplicity). Sliding window with a "missing" counter.
// O(b + s) time, O(alphabet) space.

String smallestSubstringContaining(String bigString, String smallString) {
  final need = <int, int>{};
  for (final c in smallString.codeUnits) {
    need.update(c, (v) => v + 1, ifAbsent: () => 1);
  }
  var missing = smallString.length; // characters still required, counting multiplicity
  var bestStart = 0, bestLen = -1;
  var left = 0;
  for (var right = 0; right < bigString.length; right++) {
    final c = bigString.codeUnitAt(right);
    if (need.containsKey(c)) {
      if (need[c]! > 0) missing--;
      need[c] = need[c]! - 1; // may go negative: surplus copies inside the window
    }
    while (missing == 0) {
      if (bestLen == -1 || right - left + 1 < bestLen) {
        bestStart = left;
        bestLen = right - left + 1;
      }
      final lc = bigString.codeUnitAt(left++);
      if (need.containsKey(lc)) {
        need[lc] = need[lc]! + 1;
        if (need[lc]! > 0) missing++; // removed a required copy
      }
    }
  }
  return bestLen == -1 ? '' : bigString.substring(bestStart, bestStart + bestLen);
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(smallestSubstringContaining('abcd\$ef\$axb\$c\$', '\$\$abf'), 'f\$axb\$');
  check(smallestSubstringContaining('ADOBECODEBANC', 'ABC'), 'BANC');
  check(smallestSubstringContaining('a', 'aa'), '');
}
