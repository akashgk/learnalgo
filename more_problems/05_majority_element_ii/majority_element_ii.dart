// Majority Element II: all values appearing more than n/3 times.
// Extended Boyer-Moore voting with two candidates, then a verification pass.
// O(n) time, O(1) space.

List<int> majorityElementII(List<int> nums) {
  int? c1, c2;
  var n1 = 0, n2 = 0;
  for (final x in nums) {
    if (x == c1) {
      n1++;
    } else if (x == c2) {
      n2++;
    } else if (n1 == 0) {
      c1 = x;
      n1 = 1;
    } else if (n2 == 0) {
      c2 = x;
      n2 = 1;
    } else {
      // x differs from both candidates: cancel one copy of each of the three values.
      n1--;
      n2--;
    }
  }
  // Voting only guarantees that the true answers are among the candidates; verify them.
  final result = <int>[];
  for (final c in [c1, c2]) {
    if (c != null && nums.where((x) => x == c).length > nums.length ~/ 3) result.add(c);
  }
  return result..sort();
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(majorityElementII([3, 2, 3]), [3]);
  check(majorityElementII([1]), [1]);
  check(majorityElementII([1, 2]), [1, 2]);
  check(majorityElementII([1, 1, 1, 3, 3, 2, 2, 2]), [1, 2]);
  check(majorityElementII([1, 2, 3, 4]), []); // candidates exist but fail verification
  check(majorityElementII([2, 2, 1, 3]), [2]); // 2 appears twice; the bar is more than 4 ~/ 3 = 1
}
