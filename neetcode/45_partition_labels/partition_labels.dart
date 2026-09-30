// Partition Labels: split the string into as many parts as possible so that each letter appears in
// at most one part; return the part sizes.
// Record each letter's last index. Scan, extending the current part's end to the last occurrence of
// every letter seen; when the scan reaches that end, close the part. O(n) time, O(1) space (26).

List<int> partitionLabels(String s) {
  final last = List<int>.filled(26, 0);
  for (var i = 0; i < s.length; i++) {
    last[s.codeUnitAt(i) - 97] = i;
  }
  final sizes = <int>[];
  var start = 0, end = 0;
  for (var i = 0; i < s.length; i++) {
    final l = last[s.codeUnitAt(i) - 97];
    if (l > end) end = l; // this letter forces the part to reach at least l
    if (i == end) {
      // Every letter in s[start..end] has its last occurrence inside: safe to cut here.
      sizes.add(end - start + 1);
      start = i + 1;
    }
  }
  return sizes;
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(partitionLabels('ababcbacadefegdehijhklij'), [9, 7, 8]);
  check(partitionLabels('eccbbbbdec'), [10]);
  check(partitionLabels('abc'), [1, 1, 1]);
}
