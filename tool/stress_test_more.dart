// Randomized cross-checks for the more_problems/ set: compares solutions against independent,
// deliberately naive brute forces on random small inputs. Run: dart run tool/stress_test_more.dart

import 'dart:io';
import 'dart:math';
import '../more_problems/01_best_time_to_buy_and_sell_stock/best_time_to_buy_and_sell_stock.dart' as p01;
import '../more_problems/02_next_permutation/next_permutation.dart' as p02;
import '../more_problems/03_rotate_matrix/rotate_matrix.dart' as p03;
import '../more_problems/04_set_matrix_zeroes/set_matrix_zeroes.dart' as p04;
import '../more_problems/05_majority_element_ii/majority_element_ii.dart' as p05;
import '../more_problems/06_subarray_sum_equals_k/subarray_sum_equals_k.dart' as p06;
import '../more_problems/07_maximum_product_subarray/maximum_product_subarray.dart' as p07;
import '../more_problems/08_find_the_duplicate_number/find_the_duplicate_number.dart' as p08;
import '../more_problems/09_top_k_frequent_elements/top_k_frequent_elements.dart' as p09;
import '../more_problems/10_container_with_most_water/container_with_most_water.dart' as p10;
import '../more_problems/11_find_minimum_in_rotated_sorted_array/find_minimum_in_rotated_sorted_array.dart' as p11;
import '../more_problems/12_single_element_in_sorted_array/single_element_in_sorted_array.dart' as p12;
import '../more_problems/13_koko_eating_bananas/koko_eating_bananas.dart' as p13;
import '../more_problems/14_split_array_largest_sum/split_array_largest_sum.dart' as p14;
import '../more_problems/15_aggressive_cows/aggressive_cows.dart' as p15;
import '../more_problems/16_longest_repeating_character_replacement/longest_repeating_character_replacement.dart'
    as p16;
import '../more_problems/17_binary_subarrays_with_sum/binary_subarrays_with_sum.dart' as p17;
import '../more_problems/18_sliding_window_maximum/sliding_window_maximum.dart' as p18;
import '../more_problems/19_sum_of_subarray_minimums/sum_of_subarray_minimums.dart' as p19;
import '../more_problems/20_remove_k_digits/remove_k_digits.dart' as p20;
import '../more_problems/21_maximal_rectangle/maximal_rectangle.dart' as p21;
import '../more_problems/22_copy_list_with_random_pointer/copy_list_with_random_pointer.dart' as p22;
import '../more_problems/23_reverse_nodes_in_k_group/reverse_nodes_in_k_group.dart' as p23;
import '../more_problems/24_combination_sum/combination_sum.dart' as p24;
import '../more_problems/25_subsets_ii/subsets_ii.dart' as p25;
import '../more_problems/26_word_search/word_search.dart' as p26;
import '../more_problems/27_palindrome_partitioning/palindrome_partitioning.dart' as p27;
import '../more_problems/28_permutation_sequence/permutation_sequence.dart' as p28;
import '../more_problems/30_construct_binary_tree_from_preorder_inorder/construct_binary_tree_from_preorder_inorder.dart'
    as p30;
import '../more_problems/31_serialize_and_deserialize_binary_tree/serialize_and_deserialize_binary_tree.dart' as p31;
import '../more_problems/32_morris_inorder_traversal/morris_inorder_traversal.dart' as p32;
import '../more_problems/34_alien_dictionary/alien_dictionary.dart' as p34;
import '../more_problems/35_cheapest_flights_within_k_stops/cheapest_flights_within_k_stops.dart' as p35;
import '../more_problems/37_kosaraju_scc/kosaraju_scc.dart' as p37;
import '../more_problems/38_floyd_warshall/floyd_warshall.dart' as p38;
import '../more_problems/39_partition_equal_subset_sum/partition_equal_subset_sum.dart' as p39;
import '../more_problems/40_longest_palindromic_subsequence/longest_palindromic_subsequence.dart' as p40;
import '../more_problems/41_distinct_subsequences/distinct_subsequences.dart' as p41;
import '../more_problems/42_wildcard_matching/wildcard_matching.dart' as p42;
import '../more_problems/43_burst_balloons/burst_balloons.dart' as p43;
import '../more_problems/44_cherry_pickup_ii/cherry_pickup_ii.dart' as p44;
import '../more_problems/45_non_overlapping_intervals/non_overlapping_intervals.dart' as p45;
import '../more_problems/46_valid_parenthesis_string/valid_parenthesis_string.dart' as p46;
import '../more_problems/47_task_scheduler/task_scheduler.dart' as p47;
import '../more_problems/48_maximum_xor_of_two_numbers/maximum_xor_of_two_numbers.dart' as p48;
import '../more_problems/49_single_number_iii/single_number_iii.dart' as p49;
import '../more_problems/50_lfu_cache/lfu_cache.dart' as p50;

final rng = Random(11);
var failures = 0;
void expectEq(String name, Object? got, Object? want, Object? input) {
  if ('$got' != '$want') {
    failures++;
    if (failures < 30) print('FAIL $name input=$input got=$got want=$want');
  }
}

List<int> randList(int minLen, int maxLen, int lo, int hi) =>
    List.generate(minLen + rng.nextInt(maxLen - minLen + 1), (_) => lo + rng.nextInt(hi - lo + 1));

/// All permutations of [a] (with duplicates kept), in no particular order.
List<List<int>> perms(List<int> a) {
  if (a.length <= 1) return [a];
  return [
    for (var i = 0; i < a.length; i++)
      for (final rest in perms([...a.sublist(0, i), ...a.sublist(i + 1)])) [a[i], ...rest],
  ];
}

int cmpList(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

void main() {
  for (var t = 0; t < 300; t++) {
    final a = randList(1, 9, -6, 9);
    final n = a.length;

    // 01 stock
    var best01 = 0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        best01 = max(best01, a[j] - a[i]);
      }
    }
    expectEq('01 maxProfit', p01.maxProfit(a), best01, a);

    // 06 subarray sum k, 07 max product, 10 container, 19 subarray mins
    final k = rng.nextInt(11) - 5;
    var c06 = 0, best07 = a[0];
    for (var i = 0; i < n; i++) {
      var s = 0, p = 1;
      for (var j = i; j < n; j++) {
        s += a[j];
        p *= a[j];
        if (s == k) c06++;
        best07 = max(best07, p);
      }
    }
    expectEq('06 subarraySum', p06.subarraySum(a, k), c06, (a, k));
    expectEq('07 maxProduct', p07.maxProduct(a), best07, a);
    final pos = [for (final x in a) x.abs() + 1];
    var sum19p = 0;
    for (var i = 0; i < n; i++) {
      var mn = pos[i];
      for (var j = i; j < n; j++) {
        mn = min(mn, pos[j]);
        sum19p += mn;
      }
    }
    expectEq('19 sumSubarrayMins', p19.sumSubarrayMins(pos), sum19p % p19.mod, pos);
    var best10 = 0;
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        best10 = max(best10, min(pos[i], pos[j]) * (j - i));
      }
    }
    expectEq('10 maxArea', p10.maxArea(pos), best10, pos);

    // 02 next permutation (values with duplicates)
    final small = randList(1, 6, 0, 3);
    final distinctPerms = {for (final p in perms(small)) '$p': p}.values.toList()..sort(cmpList);
    final idx = distinctPerms.indexWhere((p) => cmpList(p, small) == 0);
    final want02 = distinctPerms[(idx + 1) % distinctPerms.length];
    final got02 = [...small];
    p02.nextPermutation(got02);
    expectEq('02 nextPermutation', got02, want02, small);

    // 05 majority II
    final m5 = randList(0, 10, 1, 3);
    final want05 = [
      for (final v in m5.toSet())
        if (m5.where((x) => x == v).length > m5.length ~/ 3) v,
    ]..sort();
    expectEq('05 majorityII', p05.majorityElementII(m5), want05, m5);

    // 09 top k: the returned values must have the k highest frequencies
    final m9 = randList(1, 12, 0, 5);
    final freq = <int, int>{};
    for (final x in m9) {
      freq[x] = (freq[x] ?? 0) + 1;
    }
    final k9 = 1 + rng.nextInt(freq.length);
    final got9 = p09.topKFrequent(m9, k9);
    final topFreqs = (freq.values.toList()..sort((x, y) => y - x)).take(k9).toList();
    expectEq('09 topK freqs', (got9.map((v) => freq[v]!).toList()..sort((x, y) => y - x)), topFreqs, (m9, k9));
    expectEq('09 topK distinct', got9.toSet().length, k9, (m9, k9));

    // 17 binary subarrays
    final bin = randList(0, 10, 0, 1);
    final goal = rng.nextInt(4);
    var c17 = 0;
    for (var i = 0; i < bin.length; i++) {
      var s = 0;
      for (var j = i; j < bin.length; j++) {
        s += bin[j];
        if (s == goal) c17++;
      }
    }
    expectEq('17 binarySubarrays', p17.numSubarraysWithSum(bin, goal), c17, (bin, goal));

    // 18 sliding max
    final w = 1 + rng.nextInt(n);
    expectEq(
      '18 slidingMax',
      p18.maxSlidingWindow(a, w),
      [for (var i = 0; i + w <= n; i++) a.sublist(i, i + w).reduce(max)],
      (a, w),
    );

    // 48 max xor
    final nn = randList(1, 8, 0, 1000);
    var best48 = 0;
    for (final x in nn) {
      for (final y in nn) {
        best48 = max(best48, x ^ y);
      }
    }
    expectEq('48 maxXor', p48.findMaximumXOR(nn), best48, nn);
  }

  for (var t = 0; t < 200; t++) {
    // 03 rotate
    final n3 = 1 + rng.nextInt(5);
    final m3 = [for (var i = 0; i < n3; i++) randList(n3, n3, 0, 9)];
    final want3 = List.generate(n3, (i) => List.generate(n3, (j) => m3[n3 - 1 - j][i]));
    final g3a = [
          for (final r in m3) [...r],
        ],
        g3b = [
          for (final r in m3) [...r],
        ];
    p03.rotate(g3a);
    p03.rotateLayers(g3b);
    expectEq('03 rotate', g3a, want3, m3);
    expectEq('03 rotateLayers', g3b, want3, m3);

    // 04 set zeroes
    final r4 = 1 + rng.nextInt(4), c4 = 1 + rng.nextInt(4);
    final m4 = [for (var i = 0; i < r4; i++) randList(c4, c4, 0, 3)];
    final want4 = [
      for (var i = 0; i < r4; i++)
        [for (var j = 0; j < c4; j++) (m4[i].contains(0) || m4.any((row) => row[j] == 0)) ? 0 : m4[i][j]],
    ];
    final g4 = [
      for (final r in m4) [...r],
    ];
    p04.setZeroes(g4);
    expectEq('04 setZeroes', g4, want4, m4);

    // 08 duplicate: n + 1 values in [1, n], one value repeated (>= 2 times), others at most once
    final n8 = 1 + rng.nextInt(8);
    final d8 = 1 + rng.nextInt(n8);
    final others = [for (var v = 1; v <= n8; v++) v]
      ..remove(d8)
      ..shuffle(rng);
    final copies = 2 + rng.nextInt(n8);
    final a8 = [...List.filled(copies, d8), ...others.take(n8 + 1 - copies)]..shuffle(rng);
    expectEq('08 findDuplicate', p08.findDuplicate(a8), d8, a8);
    expectEq('08 findDuplicateByCounting', p08.findDuplicateByCounting(a8), d8, a8);

    // 11 rotated min
    final s11 = ({for (var i = 0; i < 1 + rng.nextInt(8); i++) rng.nextInt(50)}.toList()..sort());
    final rot = rng.nextInt(s11.length);
    final a11 = [...s11.sublist(rot), ...s11.sublist(0, rot)];
    expectEq('11 findMin', p11.findMin(a11), s11.first, a11);

    // 12 single element
    final vals = ({for (var i = 0; i < 1 + rng.nextInt(7); i++) rng.nextInt(30)}.toList()..sort());
    final single = vals[rng.nextInt(vals.length)];
    final a12 = [
      for (final v in vals) ...(v == single ? [v] : [v, v]),
    ];
    expectEq('12 single', p12.singleNonDuplicate(a12), single, a12);

    // 13 koko
    final piles = randList(1, 6, 1, 30);
    final h = piles.length + rng.nextInt(20);
    var k13 = 1;
    while (piles.fold(0, (s, p) => s + (p + k13 - 1) ~/ k13) > h) {
      k13++;
    }
    expectEq('13 koko', p13.minEatingSpeed(piles, h), k13, (piles, h));

    // 14 split array: try every way to place k - 1 cuts
    final a14 = randList(1, 7, 0, 20);
    final k14 = 1 + rng.nextInt(a14.length);
    int bestSplit(int start, int parts) {
      if (parts == 1) return a14.sublist(start).fold(0, (s, x) => s + x);
      var best = 1 << 40;
      for (var end = start + 1; end <= a14.length - parts + 1; end++) {
        final first = a14.sublist(start, end).fold(0, (s, x) => s + x);
        best = min(best, max(first, bestSplit(end, parts - 1)));
      }
      return best;
    }

    expectEq('14 splitArray', p14.splitArray(a14, k14), bestSplit(0, k14), (a14, k14));

    // 15 aggressive cows: every subset of the right size
    final st = ({for (var i = 0; i < 2 + rng.nextInt(6); i++) rng.nextInt(40)}.toList());
    if (st.length >= 2) {
      final cows = 2 + rng.nextInt(st.length - 1);
      final sorted = [...st]..sort();
      var best15 = 0;
      for (var mask = 0; mask < 1 << sorted.length; mask++) {
        final pick = [
          for (var i = 0; i < sorted.length; i++)
            if (mask & (1 << i) != 0) sorted[i],
        ];
        if (pick.length != cows) continue;
        var gap = 1 << 40;
        for (var i = 1; i < pick.length; i++) {
          gap = min(gap, pick[i] - pick[i - 1]);
        }
        best15 = max(best15, gap);
      }
      expectEq('15 aggressiveCows', p15.aggressiveCows(st, cows), best15, (st, cows));
    }

    // 16 character replacement
    final s16 = String.fromCharCodes(randList(0, 10, 65, 67));
    final k16 = rng.nextInt(3);
    var best16 = 0;
    for (var i = 0; i < s16.length; i++) {
      for (var j = i; j < s16.length; j++) {
        final sub = s16.substring(i, j + 1);
        final most = [for (final c in 'ABC'.split('')) sub.split('').where((x) => x == c).length].reduce(max);
        if (sub.length - most <= k16) best16 = max(best16, sub.length);
      }
    }
    expectEq('16 charReplacement', p16.characterReplacement(s16, k16), best16, (s16, k16));

    // 20 remove k digits: every subset of positions to keep
    final digits = String.fromCharCodes(randList(1, 7, 48, 51));
    final k20 = rng.nextInt(digits.length + 1);
    BigInt? best20;
    for (var mask = 0; mask < 1 << digits.length; mask++) {
      final keep = [
        for (var i = 0; i < digits.length; i++)
          if (mask & (1 << i) != 0) digits[i],
      ];
      if (keep.length != digits.length - k20) continue;
      final v = keep.isEmpty ? BigInt.zero : BigInt.parse(keep.join());
      if (best20 == null || v < best20) best20 = v;
    }
    expectEq('20 removeKdigits', p20.removeKdigits(digits, k20), '$best20', (digits, k20));

    // 21 maximal rectangle: every rectangle
    final r21 = 1 + rng.nextInt(4), c21 = 1 + rng.nextInt(4);
    final g21 = [for (var i = 0; i < r21; i++) randList(c21, c21, 0, 1).join()];
    var best21 = 0;
    for (var r1 = 0; r1 < r21; r1++) {
      for (var r2 = r1; r2 < r21; r2++) {
        for (var q1 = 0; q1 < c21; q1++) {
          for (var q2 = q1; q2 < c21; q2++) {
            var ok = true;
            for (var r = r1; r <= r2; r++) {
              for (var q = q1; q <= q2; q++) {
                if (g21[r][q] != '1') ok = false;
              }
            }
            if (ok) best21 = max(best21, (r2 - r1 + 1) * (q2 - q1 + 1));
          }
        }
      }
    }
    expectEq('21 maximalRectangle', p21.maximalRectangle(g21), best21, g21);

    // 22 copy random list
    final len22 = rng.nextInt(6);
    final spec = [
      for (var i = 0; i < len22; i++) [rng.nextInt(10), rng.nextBool() ? null : rng.nextInt(len22)],
    ];
    final head22 = p22.build(spec);
    expectEq('22 copyRandomList', p22.encode(p22.copyRandomList(head22)), spec, spec);
    expectEq('22 original intact', p22.encode(head22), spec, spec);

    // 23 reverse k group
    final l23 = randList(0, 9, 0, 9);
    final k23 = 1 + rng.nextInt(4);
    final want23 = <int>[];
    for (var i = 0; i < l23.length; i += k23) {
      final chunk = l23.sublist(i, min(i + k23, l23.length));
      want23.addAll(chunk.length == k23 ? chunk.reversed : chunk);
    }
    expectEq('23 reverseKGroup', p23.toList(p23.reverseKGroup(p23.fromList(l23), k23)), want23, (l23, k23));

    // 24 combination sum: count equals the number of multisets (coin change ways)
    final cands = ({for (var i = 0; i < 1 + rng.nextInt(4); i++) 1 + rng.nextInt(6)}.toList());
    final target24 = rng.nextInt(12) + 1;
    final ways = List<int>.filled(target24 + 1, 0)..[0] = 1;
    for (final c in cands) {
      for (var s = c; s <= target24; s++) {
        ways[s] += ways[s - c];
      }
    }
    final got24 = p24.combinationSum(cands, target24);
    expectEq('24 combinationSum count', got24.length, ways[target24], (cands, target24));
    expectEq('24 combinationSum sums', got24.every((c) => c.fold(0, (s, x) => s + x) == target24), true, cands);

    // 25 subsets II: distinct sorted subsets via bitmask
    final a25 = randList(0, 7, 0, 3);
    final set25 = <String>{};
    for (var mask = 0; mask < 1 << a25.length; mask++) {
      final sub = [
        for (var i = 0; i < a25.length; i++)
          if (mask & (1 << i) != 0) a25[i],
      ]..sort();
      set25.add('$sub');
    }
    final got25 = p25.subsetsWithDup(a25).map((s) => '$s').toList();
    expectEq('25 subsetsII', (got25..sort()), (set25.toList()..sort()), a25);

    // 27 palindrome partitioning: every set of cut positions
    final s27 = String.fromCharCodes(randList(1, 8, 97, 98));
    bool isPal(String x) => x == x.split('').reversed.join();
    var c27 = 0;
    for (var mask = 0; mask < 1 << (s27.length - 1); mask++) {
      var start = 0, ok = true;
      for (var i = 1; i <= s27.length; i++) {
        if (i == s27.length || mask & (1 << (i - 1)) != 0) {
          if (!isPal(s27.substring(start, i))) ok = false;
          start = i;
        }
      }
      if (ok) c27++;
    }
    expectEq('27 palindromePartition count', p27.partition(s27).length, c27, s27);

    // 28 permutation sequence
    final n28 = 1 + rng.nextInt(6);
    final all28 = perms([for (var i = 1; i <= n28; i++) i])..sort(cmpList);
    final k28 = 1 + rng.nextInt(all28.length);
    expectEq('28 getPermutation', p28.getPermutation(n28, k28), all28[k28 - 1].join(), (n28, k28));

    // 39 partition: bitmask
    final a39 = randList(1, 8, 1, 12);
    final total39 = a39.fold(0, (s, x) => s + x);
    var can39 = false;
    for (var mask = 0; mask < 1 << a39.length; mask++) {
      var s = 0;
      for (var i = 0; i < a39.length; i++) {
        if (mask & (1 << i) != 0) s += a39[i];
      }
      if (2 * s == total39) can39 = true;
    }
    expectEq('39 canPartition', p39.canPartition(a39), can39, a39);

    // 40 longest palindromic subsequence: bitmask
    final s40 = String.fromCharCodes(randList(0, 10, 97, 99));
    var best40 = 0;
    for (var mask = 0; mask < 1 << s40.length; mask++) {
      final sub = [
        for (var i = 0; i < s40.length; i++)
          if (mask & (1 << i) != 0) s40[i],
      ];
      if (sub.join() == sub.reversed.join()) best40 = max(best40, sub.length);
    }
    expectEq('40 LPS', p40.longestPalindromeSubseq(s40), best40, s40);

    // 41 distinct subsequences: plain recursion
    final s41 = String.fromCharCodes(randList(0, 9, 97, 98));
    final t41 = String.fromCharCodes(randList(0, 3, 97, 98));
    int count41(int i, int j) {
      if (j == t41.length) return 1;
      if (i == s41.length) return 0;
      return count41(i + 1, j) + (s41[i] == t41[j] ? count41(i + 1, j + 1) : 0);
    }

    expectEq('41 numDistinct', p41.numDistinct(s41, t41), count41(0, 0), (s41, t41));

    // 42 wildcard: plain recursion
    final s42 = String.fromCharCodes(randList(0, 6, 97, 98));
    final p42s = [
      for (var i = 0; i < rng.nextInt(6); i++) ['a', 'b', '?', '*'][rng.nextInt(4)],
    ].join();
    bool match(int i, int j) {
      if (j == p42s.length) return i == s42.length;
      if (p42s[j] == '*') return match(i, j + 1) || (i < s42.length && match(i + 1, j));
      return i < s42.length && (p42s[j] == '?' || p42s[j] == s42[i]) && match(i + 1, j + 1);
    }

    expectEq('42 wildcard', p42.isMatch(s42, p42s), match(0, 0), (s42, p42s));

    // 43 burst balloons: every burst order
    final a43 = randList(0, 6, 0, 9);
    var best43 = 0;
    for (final order in perms([for (var i = 0; i < a43.length; i++) i])) {
      final alive = [for (var i = 0; i < a43.length; i++) i];
      var coins = 0;
      for (final b in order) {
        final pos = alive.indexOf(b);
        final left = pos == 0 ? 1 : a43[alive[pos - 1]];
        final right = pos == alive.length - 1 ? 1 : a43[alive[pos + 1]];
        coins += left * a43[b] * right;
        alive.removeAt(pos);
      }
      best43 = max(best43, coins);
    }
    expectEq('43 burstBalloons', p43.maxCoins(a43), best43, a43);

    // 44 cherry pickup II: recursion over both robots' moves
    final r44 = 1 + rng.nextInt(4), c44 = 1 + rng.nextInt(4);
    final g44 = [for (var i = 0; i < r44; i++) randList(c44, c44, 0, 9)];
    int go(int r, int x, int y) {
      if (x < 0 || y < 0 || x >= c44 || y >= c44) return -(1 << 40);
      final here = g44[r][x] + (x == y ? 0 : g44[r][y]);
      if (r == r44 - 1) return here;
      var best = -(1 << 40);
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          best = max(best, go(r + 1, x + dx, y + dy));
        }
      }
      return here + best;
    }

    expectEq('44 cherryPickup', p44.cherryPickup(g44), go(0, 0, c44 - 1), g44);

    // 45 non-overlapping intervals: largest compatible subset by bitmask
    final iv = [
      for (var i = 0; i < rng.nextInt(8); i++) [rng.nextInt(10), 0],
    ];
    for (final x in iv) {
      x[1] = x[0] + 1 + rng.nextInt(5);
    }
    var keep45 = 0;
    for (var mask = 0; mask < 1 << iv.length; mask++) {
      final pick = [
        for (var i = 0; i < iv.length; i++)
          if (mask & (1 << i) != 0) iv[i],
      ]..sort((x, y) => x[0].compareTo(y[0]));
      var ok = true;
      for (var i = 1; i < pick.length; i++) {
        if (pick[i][0] < pick[i - 1][1]) ok = false;
      }
      if (ok) keep45 = max(keep45, pick.length);
    }
    expectEq('45 eraseOverlap', p45.eraseOverlapIntervals(iv), iv.length - keep45, iv);

    // 46 valid parenthesis string: every replacement of the stars
    final s46 = [
      for (var i = 0; i < rng.nextInt(9); i++) ['(', ')', '*'][rng.nextInt(3)],
    ].join();
    bool valid46(int i, int open) {
      if (open < 0) return false;
      if (i == s46.length) return open == 0;
      final ch = s46[i];
      if (ch == '(') return valid46(i + 1, open + 1);
      if (ch == ')') return valid46(i + 1, open - 1);
      return valid46(i + 1, open) || valid46(i + 1, open + 1) || valid46(i + 1, open - 1);
    }

    expectEq('46 checkValidString', p46.checkValidString(s46), valid46(0, 0), s46);

    // 47 task scheduler vs a step-by-step simulation (run the available task with the most remaining)
    final tasks = [for (var i = 0; i < 1 + rng.nextInt(10); i++) String.fromCharCode(65 + rng.nextInt(4))];
    final n47 = rng.nextInt(4);
    final remaining = <String, int>{};
    for (final x in tasks) {
      remaining[x] = (remaining[x] ?? 0) + 1;
    }
    final readyAt = <String, int>{for (final x in remaining.keys) x: 0};
    var time = 0;
    while (remaining.values.any((c) => c > 0)) {
      String? pick;
      for (final x in remaining.keys) {
        if (remaining[x]! > 0 && readyAt[x]! <= time && (pick == null || remaining[x]! > remaining[pick]!)) pick = x;
      }
      if (pick != null) {
        remaining[pick] = remaining[pick]! - 1;
        readyAt[pick] = time + n47 + 1;
      }
      time++;
    }
    expectEq('47 leastInterval', p47.leastInterval(tasks, n47), time, (tasks, n47));

    // 49 single number III
    final pool = ({for (var i = 0; i < 2 + rng.nextInt(6); i++) rng.nextInt(40) - 20}.toList());
    if (pool.length >= 2) {
      final twoSingles = [pool[0], pool[1]]..sort();
      final a49 = [
        pool[0],
        pool[1],
        for (final v in pool.skip(2)) ...[v, v],
      ]..shuffle(rng);
      expectEq('49 singleNumberIII', p49.singleNumber(a49), twoSingles, a49);
    }
  }

  // Trees: 30 build from traversals, 31 serialize round trip, 32 Morris vs recursion
  for (var t = 0; t < 200; t++) {
    final values = [for (var i = 0; i < rng.nextInt(12); i++) i]..shuffle(rng);
    p30.TreeNode? insertRandom(p30.TreeNode? root, int v) {
      if (root == null) return p30.TreeNode(v);
      if (rng.nextBool()) {
        root.left = insertRandom(root.left, v);
      } else {
        root.right = insertRandom(root.right, v);
      }
      return root;
    }

    p30.TreeNode? tree;
    for (final v in values) {
      tree = insertRandom(tree, v);
    }
    final pre = p30.preorderOf(tree), ino = p30.inorderOf(tree);
    final rebuilt = p30.buildTree(pre, ino);
    expectEq('30 buildTree', (p30.preorderOf(rebuilt), p30.inorderOf(rebuilt)), (pre, ino), values);

    // Same shape in the other files' node classes.
    p31.TreeNode? to31(p30.TreeNode? x) => x == null ? null : p31.TreeNode(x.value, to31(x.left), to31(x.right));
    p32.TreeNode? to32(p30.TreeNode? x) => x == null ? null : p32.TreeNode(x.value, to32(x.left), to32(x.right));
    final s = p31.serialize(to31(tree));
    expectEq('31 roundTrip', p31.serialize(p31.deserialize(s)), s, values);
    final t32 = to32(tree);
    expectEq('32 morris', p32.morrisInorder(t32), ino, values);
    expectEq('32 restored', p32.recursiveInorder(t32), ino, values);
  }

  // Graphs
  for (var t = 0; t < 150; t++) {
    final n = 1 + rng.nextInt(6);
    final edges = <List<int>>[
      for (var i = 0; i < rng.nextInt(12); i++) [rng.nextInt(n), rng.nextInt(n), 1 + rng.nextInt(9)],
    ];

    // 35 cheapest flights: DFS over every path with at most k + 1 flights
    final src = rng.nextInt(n), dst = rng.nextInt(n), k = rng.nextInt(3);
    var best35 = 1 << 40;
    void dfs(int u, int flightsUsed, int cost) {
      if (u == dst) best35 = min(best35, cost);
      if (flightsUsed == k + 1) return;
      for (final e in edges) {
        if (e[0] == u) dfs(e[1], flightsUsed + 1, cost + e[2]);
      }
    }

    dfs(src, 0, 0);
    expectEq('35 cheapestFlights', p35.findCheapestPrice(n, edges, src, dst, k), best35 == 1 << 40 ? -1 : best35, (
      n,
      edges,
      src,
      dst,
      k,
    ));

    // 37 SCC: i and j share a component iff each reaches the other
    final reach = List.generate(n, (i) => List<bool>.generate(n, (j) => i == j));
    for (final e in edges) {
      reach[e[0]][e[1]] = true;
    }
    for (var m = 0; m < n; m++) {
      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          if (reach[i][m] && reach[m][j]) reach[i][j] = true;
        }
      }
    }
    final comp = List<int>.filled(n, -1);
    for (final (id, c) in p37.kosaraju(n, edges).indexed) {
      for (final v in c) {
        comp[v] = id;
      }
    }
    var ok37 = true;
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        if ((comp[i] == comp[j]) != (reach[i][j] && reach[j][i])) ok37 = false;
      }
    }
    expectEq('37 kosaraju', ok37, true, (n, edges));

    // 38 Floyd-Warshall vs Bellman-Ford from every source (positive weights)
    final d = p38.floydWarshall(n, edges)!;
    for (var s = 0; s < n; s++) {
      final dist = List<int>.filled(n, p38.inf)..[s] = 0;
      for (var round = 0; round < n; round++) {
        for (final e in edges) {
          if (dist[e[0]] != p38.inf && dist[e[0]] + e[2] < dist[e[1]]) dist[e[1]] = dist[e[0]] + e[2];
        }
      }
      expectEq('38 floydWarshall', d[s], dist, (n, edges));
    }
  }

  // 34 alien dictionary: words sorted under a hidden order must yield a consistent order
  for (var t = 0; t < 150; t++) {
    final letters = 'abcde'.split('')..shuffle(rng);
    final rank = {for (var i = 0; i < letters.length; i++) letters[i]: i};
    final words = [
      for (var i = 0; i < 1 + rng.nextInt(6); i++)
        [for (var j = 0; j < 1 + rng.nextInt(3); j++) letters[rng.nextInt(5)]].join(),
    ];
    words.sort((x, y) {
      for (var i = 0; i < x.length && i < y.length; i++) {
        if (x[i] != y[i]) return rank[x[i]]!.compareTo(rank[y[i]]!);
      }
      return x.length.compareTo(y.length);
    });
    final order = p34.alienOrder(words);
    final used = {for (final w in words) ...w.split('')};
    expectEq('34 alienOrder letters', order.split('')..sort(), used.toList()..sort(), words);
    expectEq('34 alienOrder valid', p34.isValidOrder(words, order), true, words);
  }

  // 26 word search: plant a random path, it must be found; compare with a brute path search
  for (var t = 0; t < 150; t++) {
    final r = 1 + rng.nextInt(3), c = 1 + rng.nextInt(3);
    final board = [
      for (var i = 0; i < r; i++) [for (var j = 0; j < c; j++) String.fromCharCode(97 + rng.nextInt(2))],
    ];
    final word = String.fromCharCodes(randList(1, 4, 97, 98));
    var found = false;
    void walk(int x, int y, int i, Set<int> used) {
      if (found || x < 0 || y < 0 || x >= r || y >= c || used.contains(x * c + y) || board[x][y] != word[i]) return;
      if (i == word.length - 1) {
        found = true;
        return;
      }
      final next = {...used, x * c + y};
      walk(x + 1, y, i + 1, next);
      walk(x - 1, y, i + 1, next);
      walk(x, y + 1, i + 1, next);
      walk(x, y - 1, i + 1, next);
    }

    for (var x = 0; x < r; x++) {
      for (var y = 0; y < c; y++) {
        walk(x, y, 0, {});
      }
    }
    expectEq('26 wordSearch', p26.exist(board, word), found, (board, word));
  }

  // 50 LFU: compare with a naive model that scans for the victim
  for (var t = 0; t < 100; t++) {
    final cap = rng.nextInt(4);
    final cache = p50.LFUCache(cap);
    final model = <int, List<int>>{}; // key -> [value, freq, lastUsedTime]
    var clock = 0;
    for (var op = 0; op < 30; op++) {
      final key = rng.nextInt(5);
      if (rng.nextBool()) {
        final e = model[key];
        if (e != null) {
          e[1]++;
          e[2] = clock++;
        }
        expectEq('50 LFU get', cache.get(key), e == null ? -1 : e[0], (cap, op));
      } else {
        final value = rng.nextInt(100);
        cache.put(key, value);
        if (cap == 0) continue;
        final e = model[key];
        if (e != null) {
          e[0] = value;
          e[1]++;
          e[2] = clock++;
          continue;
        }
        if (model.length == cap) {
          final victim = model.entries.reduce(
            (x, y) => (x.value[1] < y.value[1] || (x.value[1] == y.value[1] && x.value[2] < y.value[2])) ? x : y,
          );
          model.remove(victim.key);
        }
        model[key] = [value, 1, clock++];
      }
    }
  }

  print(failures == 0 ? 'ALL MORE_PROBLEMS STRESS TESTS PASSED' : 'failures: $failures');
  if (failures > 0) exitCode = 1;
}
