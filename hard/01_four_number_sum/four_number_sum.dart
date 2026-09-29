// Four Number Sum: all quadruplets of distinct integers summing to target.
// Pair-sum hash map, adding pairs only AFTER using index i as the split point so each
// quadruplet is generated once. Average O(n^2) time (worst O(n^3)), O(n^2) space.

List<List<int>> fourNumberSum(List<int> array, int targetSum) {
  final pairsBySum = <int, List<(int, int)>>{};
  final quadruplets = <List<int>>[];
  for (var i = 1; i < array.length - 1; i++) {
    // Pairs (i, j) with j > i are the "second half"; look up earlier pairs as the first half.
    for (var j = i + 1; j < array.length; j++) {
      final need = targetSum - array[i] - array[j];
      for (final (a, b) in pairsBySum[need] ?? const <(int, int)>[]) {
        quadruplets.add([a, b, array[i], array[j]]);
      }
    }
    // Now register pairs (k, i) with k < i, so they are only seen by later split points.
    for (var k = 0; k < i; k++) {
      (pairsBySum[array[k] + array[i]] ??= []).add((array[k], array[i]));
    }
  }
  return quadruplets;
}

/// Sort + two pointers alternative: O(n^3) time, O(1) extra space, sorted output.
List<List<int>> fourNumberSumSorted(List<int> array, int target) {
  final a = [...array]..sort();
  final out = <List<int>>[];
  for (var i = 0; i < a.length - 3; i++) {
    for (var j = i + 1; j < a.length - 2; j++) {
      var lo = j + 1, hi = a.length - 1;
      while (lo < hi) {
        final s = a[i] + a[j] + a[lo] + a[hi];
        if (s == target) {
          out.add([a[i], a[j], a[lo++], a[hi--]]);
        } else if (s < target) {
          lo++;
        } else {
          hi--;
        }
      }
    }
  }
  return out;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

List<List<int>> normalize(List<List<int>> qs) => [
  for (final q in qs) [...q]..sort(),
]..sort((x, y) => '$x'.compareTo('$y'));

void main() {
  const input = [7, 6, 4, -1, 1, 2];
  const expected = [
    [7, 6, 4, -1],
    [7, 6, 1, 2],
  ];
  check(normalize(fourNumberSum(input, 16)), normalize(expected));
  check(normalize(fourNumberSumSorted(input, 16)), normalize(expected));
  check(fourNumberSum([1, 2, 3], 6), []);
}
