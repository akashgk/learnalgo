// Randomized cross-checks: compares ~60 solutions against independent brute-force
// implementations on random small inputs. Run: dart run tool/stress_test.dart
// Exits non-zero on the first batch of mismatches. The brute forces are deliberately naive;
// they are the "obviously correct" reference, not examples of good solutions.

import 'dart:io';
import 'dart:math';
import '../medium/01_three_number_sum/three_number_sum.dart' as tns;
import '../hard/01_four_number_sum/four_number_sum.dart' as fns;
import '../hard/02_subarray_sort/subarray_sort.dart' as ss;
import '../hard/03_largest_range/largest_range.dart' as lr;
import '../hard/04_min_rewards/min_rewards.dart' as mr;
import '../medium/06_longest_peak/longest_peak.dart' as lp;
import '../hard/05_zigzag_traverse/zigzag_traverse.dart' as zz;
import '../hard/08_count_squares/count_squares.dart' as cs;
import '../hard/18_water_area/water_area.dart' as wa;
import '../hard/19_knapsack_problem/knapsack_problem.dart' as ks;
import '../very_hard/14_longest_increasing_subsequence/longest_increasing_subsequence.dart' as lis;
import '../hard/16_longest_common_subsequence/longest_common_subsequence.dart' as lcs;
import '../medium/31_levenshtein_distance/levenshtein_distance.dart' as lev;
import '../hard/17_min_number_of_jumps/min_number_of_jumps.dart' as mj;
import '../very_hard/31_median_of_two_sorted_arrays/median_of_two_sorted_arrays.dart' as med;
import '../hard/46_quickselect/quickselect.dart' as qs;
import '../hard/48_quick_sort/quick_sort.dart' as qsort;
import '../hard/49_heap_sort/heap_sort.dart' as hsort;
import '../hard/50_radix_sort/radix_sort.dart' as rsort;
import '../very_hard/33_merge_sort/merge_sort.dart' as msort;
import '../very_hard/34_count_inversions/count_inversions.dart' as ci;
import '../very_hard/06_right_smaller_than/right_smaller_than.dart' as rst;
import '../very_hard/35_smallest_substring_containing/smallest_substring_containing.dart' as ssc;
import '../very_hard/36_longest_balanced_substring/longest_balanced_substring.dart' as lbs;
import '../very_hard/17_knuth_morris_pratt/knuth_morris_pratt.dart' as kmp;
import '../very_hard/13_palindrome_partitioning_min_cuts/palindrome_partitioning_min_cuts.dart' as ppmc;
import '../very_hard/12_max_profit_with_k_transactions/max_profit_with_k_transactions.dart' as mpk;
import '../very_hard/32_optimal_assembly_line/optimal_assembly_line.dart' as oal;
import '../hard/06_longest_subarray_with_sum/longest_subarray_with_sum.dart' as lss;
import '../very_hard/19_rectangle_mania/rectangle_mania.dart' as rm;
import '../very_hard/04_minimum_area_rectangle/minimum_area_rectangle.dart' as mar;
import '../very_hard/05_line_through_points/line_through_points.dart' as ltp;
import '../medium/64_next_greater_element/next_greater_element.dart' as nge;
import '../medium/62_best_digits/best_digits.dart' as bd;
import '../hard/24_dice_throws/dice_throws.dart' as dt;
import '../hard/25_juice_bottling/juice_bottling.dart' as jb;
import '../very_hard/16_square_of_zeroes/square_of_zeroes.dart' as sz;
import '../hard/32_laptop_rentals/laptop_rentals.dart' as lap;
import '../medium/05_spiral_traverse/spiral_traverse.dart' as sp;
import '../medium/67_longest_palindromic_substring/longest_palindromic_substring.dart' as lps;
import '../hard/53_longest_substring_without_duplication/longest_substring_without_duplication.dart' as lswd;
import '../medium/28_max_subset_sum_no_adjacent/max_subset_sum_no_adjacent.dart' as mssna;
import '../medium/30_min_number_of_coins_for_change/min_number_of_coins_for_change.dart' as mnc;
import '../medium/29_number_of_ways_to_make_change/number_of_ways_to_make_change.dart' as nwc;
import '../hard/23_maximize_expression/maximize_expression.dart' as mx;
import '../medium/33_kadanes_algorithm/kadanes_algorithm.dart' as kad;
import '../hard/44_shifted_binary_search/shifted_binary_search.dart' as sbs;
import '../hard/45_search_for_range/search_for_range.dart' as sfr;
import '../hard/47_index_equals_value/index_equals_value.dart' as iev;
import '../hard/15_max_sum_increasing_subsequence/max_sum_increasing_subsequence.dart' as msis;
import '../hard/52_largest_rectangle_under_skyline/largest_rectangle_under_skyline.dart' as lrus;
import '../hard/40_interweaving_strings/interweaving_strings.dart' as iws;
import '../medium/72_one_edit/one_edit.dart' as oe;
import '../medium/10_best_seat/best_seat.dart' as bs;
import '../very_hard/30_non_attacking_queens/non_attacking_queens.dart' as naq;
import '../hard/09_same_bsts/same_bsts.dart' as sb;
import '../hard/43_ambiguous_measurements/ambiguous_measurements.dart' as am;
import '../very_hard/15_longest_string_chain/longest_string_chain.dart' as lsc;
import '../hard/31_largest_island/largest_island.dart' as li;
import '../hard/26_dijkstras_algorithm/dijkstras_algorithm.dart' as dij;
import '../very_hard/22_two_edge_connected_graph/two_edge_connected_graph.dart' as tec;
import '../very_hard/20_airport_connections/airport_connections.dart' as ac;
import '../hard/21_numbers_in_pi/numbers_in_pi.dart' as nip;
import '../very_hard/37_strings_made_up_of_strings/strings_made_up_of_strings.dart' as smus;

final rng = Random(7);
var failures = 0;
void expectEq(String name, Object? got, Object? want, Object? input) {
  if ('$got' != '$want') {
    failures++;
    if (failures < 30) print('FAIL $name input=$input got=$got want=$want');
  }
}

List<int> randList(int maxLen, int lo, int hi) =>
    List.generate(rng.nextInt(maxLen + 1), (_) => lo + rng.nextInt(hi - lo + 1));
List<int> distinct(int maxLen, int lo, int hi) {
  final s = <int>{};
  final n = rng.nextInt(maxLen + 1);
  while (s.length < n && s.length < hi - lo + 1) {
    s.add(lo + rng.nextInt(hi - lo + 1));
  }
  return s.toList();
}

int maxOf(Iterable<int> x) => x.reduce((a, b) => a > b ? a : b);
int minOf(Iterable<int> x) => x.reduce((a, b) => a < b ? a : b);

void main() {
  for (var t = 0; t < 400; t++) {
    // three / four sum
    final a = distinct(9, -10, 10);
    final target = rng.nextInt(21) - 10;
    final brute3 = <String>{};
    for (var i = 0; i < a.length; i++)
      for (var j = i + 1; j < a.length; j++)
        for (var k = j + 1; k < a.length; k++) {
          if (a[i] + a[j] + a[k] == target) brute3.add('${([a[i], a[j], a[k]]..sort())}');
        }
    expectEq('3sum', (tns.threeNumberSum(a, target).map((x) => '$x').toList()..sort()), (brute3.toList()..sort()), a);
    final brute4 = <String>{};
    for (var i = 0; i < a.length; i++)
      for (var j = i + 1; j < a.length; j++)
        for (var k = j + 1; k < a.length; k++)
          for (var l = k + 1; l < a.length; l++) {
            if (a[i] + a[j] + a[k] + a[l] == target) brute4.add('${([a[i], a[j], a[k], a[l]]..sort())}');
          }
    expectEq(
      '4sum',
      (fns.fourNumberSum(a, target).map((x) => '${(x..sort())}').toList()..sort()),
      (brute4.toList()..sort()),
      a,
    );

    // subarray sort
    final b = randList(8, 0, 6);
    if (b.length >= 2) {
      final s = [...b]..sort();
      var st = -1, en = -1;
      for (var i = 0; i < b.length; i++) {
        if (b[i] != s[i]) {
          if (st == -1) st = i;
          en = i;
        }
      }
      expectEq('subarraySort', ss.subarraySort(b), [st, en], b);
    }
    // largest range (length)
    final c = randList(10, -5, 10);
    if (c.isNotEmpty) {
      final set = c.toSet();
      var best = 0;
      for (final x in set) {
        var e = x;
        while (set.contains(e + 1)) e++;
        if (e - x + 1 > best) best = e - x + 1;
      }
      final r = lr.largestRange(c);
      expectEq('largestRange', r[1] - r[0] + 1, best, c);
    }
    // min rewards (distinct scores): brute = max of run lengths each side
    final d = distinct(8, 0, 20);
    if (d.isNotEmpty) {
      var sum = 0;
      for (var i = 0; i < d.length; i++) {
        var l = 1;
        for (var j = i; j > 0 && d[j] > d[j - 1]; j--) l++;
        var r = 1;
        for (var j = i; j < d.length - 1 && d[j] > d[j + 1]; j++) r++;
        sum += max(l, r);
      }
      expectEq('minRewards', mr.minRewards(d), sum, d);
    }
    // longest peak
    final e = randList(10, 0, 4);
    var bestPeak = 0;
    for (var i = 0; i < e.length; i++)
      for (var j = i + 2; j < e.length; j++) {
        for (var tip = i + 1; tip < j; tip++) {
          var ok = true;
          for (var k = i; k < tip; k++) if (!(e[k] < e[k + 1])) ok = false;
          for (var k = tip; k < j; k++) if (!(e[k] > e[k + 1])) ok = false;
          if (ok && j - i + 1 > bestPeak) bestPeak = j - i + 1;
        }
      }
    expectEq('longestPeak', lp.longestPeak(e), bestPeak, e);
    // zigzag: set equality + adjacency property
    final rows = 1 + rng.nextInt(4), cols = 1 + rng.nextInt(4);
    var cnt = 0;
    final m = List.generate(rows, (_) => List.generate(cols, (_) => cnt++));
    final z = zz.zigzagTraverse(m);
    expectEq('zigzag-perm', (z.toList()..sort()), List.generate(rows * cols, (i) => i), m);
    // water area brute
    final h = randList(10, 0, 6);
    var water = 0;
    for (var i = 0; i < h.length; i++) {
      final lm = h.sublist(0, i + 1).fold(0, max), rm2 = h.sublist(i).fold(0, max);
      water += min(lm, rm2) - h[i];
    }
    expectEq('water', wa.waterArea(h), water, h);
    // knapsack brute
    final items = List.generate(rng.nextInt(7), (_) => [1 + rng.nextInt(10), 1 + rng.nextInt(8)]);
    final cap = rng.nextInt(15);
    var bestV = 0;
    for (var mask = 0; mask < 1 << items.length; mask++) {
      var v = 0, w = 0;
      for (var i = 0; i < items.length; i++)
        if (mask & (1 << i) != 0) {
          v += items[i][0];
          w += items[i][1];
        }
      if (w <= cap && v > bestV) bestV = v;
    }
    final kr = ks.knapsackProblem(items, cap);
    final chosen = kr[1] as List<int>;
    expectEq('knapsack', kr[0], bestV, items);
    expectEq('knapsack-consistent', chosen.fold<int>(0, (s, i) => s + items[i][0]), bestV, items);
    expectEq('knapsack-fits', chosen.fold<int>(0, (s, i) => s + items[i][1]) <= cap, true, items);
    // LIS length + validity
    final f = randList(10, 0, 9);
    final lisSeq = lis.longestIncreasingSubsequence(f);
    var bestLis = 0;
    for (var mask = 0; mask < 1 << f.length; mask++) {
      final sub = [
        for (var i = 0; i < f.length; i++)
          if (mask & (1 << i) != 0) f[i],
      ];
      var ok = true;
      for (var i = 1; i < sub.length; i++) if (sub[i] <= sub[i - 1]) ok = false;
      if (ok && sub.length > bestLis) bestLis = sub.length;
    }
    expectEq('lis-len', lisSeq.length, bestLis, f);
    var okInc = true;
    for (var i = 1; i < lisSeq.length; i++) if (lisSeq[i] <= lisSeq[i - 1]) okInc = false;
    var pos = 0;
    for (final x in lisSeq) {
      while (pos < f.length && f[pos] != x) pos++;
      if (pos == f.length) okInc = false;
      pos++;
    }
    expectEq('lis-valid', okInc, true, f);
    // LCS length via brute DP recursion + levenshtein brute via recursion memo-free small
    String rs(int n) => String.fromCharCodes(List.generate(rng.nextInt(n + 1), (_) => 97 + rng.nextInt(3)));
    final s1 = rs(7), s2 = rs(7);
    int lcsLen(int i, int j) => i == s1.length || j == s2.length
        ? 0
        : s1[i] == s2[j]
        ? 1 + lcsLen(i + 1, j + 1)
        : max(lcsLen(i + 1, j), lcsLen(i, j + 1));
    final lcsRes = lcs.longestCommonSubsequence(s1, s2);
    expectEq('lcs', lcsRes.length, lcsLen(0, 0), '$s1/$s2');
    int ed(int i, int j) => i == s1.length
        ? s2.length - j
        : j == s2.length
        ? s1.length - i
        : s1[i] == s2[j]
        ? ed(i + 1, j + 1)
        : 1 + min(ed(i + 1, j + 1), min(ed(i + 1, j), ed(i, j + 1)));
    expectEq('lev', lev.levenshteinDistance(s1, s2), ed(0, 0), '$s1/$s2');
    expectEq('oneEdit', oe.oneEdit(s1, s2), ed(0, 0) <= 1, '$s1/$s2');
    // interweaving brute
    final s3 = rs(6);
    if (s1.length + s2.length <= 10) {
      final s3b = rng.nextBool() ? s3 : (s1 + s2);
      bool iwb(int i, int j) {
        if (i + j == s3b.length) return i == s1.length && j == s2.length;
        return (i < s1.length && s1[i] == s3b[i + j] && iwb(i + 1, j)) ||
            (j < s2.length && s2[j] == s3b[i + j] && iwb(i, j + 1));
      }

      expectEq(
        'interweave',
        iws.interweavingStrings(s1, s2, s3b),
        s1.length + s2.length == s3b.length && iwb(0, 0),
        '$s1/$s2/$s3b',
      );
    }
    // min jumps brute BFS
    final jumps = List.generate(1 + rng.nextInt(8), (_) => 1 + rng.nextInt(3));
    final dist = List<int>.filled(jumps.length, 1 << 30)..[0] = 0;
    for (var i = 0; i < jumps.length; i++)
      for (var k = 1; k <= jumps[i] && i + k < jumps.length; k++) dist[i + k] = min(dist[i + k], dist[i] + 1);
    expectEq('minJumps', mj.minNumberOfJumps(jumps), dist.last, jumps);
    // median
    final m1 = randList(6, -5, 5)..sort(), m2 = randList(6, -5, 5)..sort();
    if (m1.length + m2.length > 0) {
      final all = [...m1, ...m2]..sort();
      final n = all.length;
      final want = n.isOdd ? all[n ~/ 2].toDouble() : (all[n ~/ 2 - 1] + all[n ~/ 2]) / 2;
      expectEq('median', med.medianOfTwoSortedArrays(m1, m2), want, '$m1 $m2');
    }
    // sorts, quickselect, inversions, right smaller
    final g = randList(12, -20, 20);
    final sorted = [...g]..sort();
    expectEq('quickSort', qsort.quickSort([...g]), sorted, g);
    expectEq('heapSort', hsort.heapSort([...g]), sorted, g);
    expectEq('mergeSort', msort.mergeSort([...g]), sorted, g);
    final nonneg = [for (final x in g) x.abs() * 37];
    expectEq('radixSort', rsort.radixSort([...nonneg]), [...nonneg]..sort(), nonneg);
    final dg = g.toSet().toList();
    if (dg.isNotEmpty) {
      final k = 1 + rng.nextInt(dg.length);
      expectEq('quickselect', qs.quickselect(dg, k), ([...dg]..sort())[k - 1], dg);
    }
    var inv = 0;
    final rsm = <int>[];
    for (var i = 0; i < g.length; i++) {
      var c2 = 0;
      for (var j = i + 1; j < g.length; j++) if (g[i] > g[j]) c2++;
      inv += c2;
      rsm.add(c2);
    }
    expectEq('inversions', ci.countInversions(g), inv, g);
    expectEq('rightSmaller', rst.rightSmallerThan(g), rsm, g);
    // search: shifted, range, index equals value
    final sd = distinct(10, -10, 20)..sort();
    if (sd.isNotEmpty) {
      final rot = rng.nextInt(sd.length);
      final shifted = [...sd.sublist(rot), ...sd.sublist(0, rot)];
      final q = rng.nextInt(31) - 10;
      expectEq('shiftedBS', sbs.shiftedBinarySearch(shifted, q), shifted.indexOf(q), '$shifted $q');
      final firstIdx = [
        for (var i = 0; i < sd.length; i++)
          if (sd[i] == i) i,
      ];
      expectEq('indexEqualsValue', iev.indexEqualsValue(sd), firstIdx.isEmpty ? -1 : firstIdx.first, sd);
    }
    final dup = randList(10, 0, 4)..sort();
    final q2 = rng.nextInt(5);
    expectEq('searchRange', sfr.searchForRange(dup, q2), [dup.indexOf(q2), dup.lastIndexOf(q2)], '$dup $q2');
    // min window
    final big = rs(10), small = rs(3);
    if (small.isNotEmpty) {
      var bestW = '';
      for (var i = 0; i < big.length; i++)
        for (var j = i + 1; j <= big.length; j++) {
          final w = big.substring(i, j);
          final cnts = <String, int>{};
          for (final ch in w.split('')) cnts[ch] = (cnts[ch] ?? 0) + 1;
          var ok = true;
          final need = <String, int>{};
          for (final ch in small.split('')) need[ch] = (need[ch] ?? 0) + 1;
          need.forEach((ch, v) {
            if ((cnts[ch] ?? 0) < v) ok = false;
          });
          if (ok && (bestW.isEmpty || w.length < bestW.length)) bestW = w;
        }
      expectEq('minWindow-len', ssc.smallestSubstringContaining(big, small).length, bestW.length, '$big/$small');
      expectEq('kmp', kmp.knuthMorrisPrattAlgorithm(big, small), big.contains(small), '$big/$small');
    }
    // balanced parens
    final par = String.fromCharCodes(List.generate(rng.nextInt(12), (_) => rng.nextBool() ? 40 : 41));
    var bestBal = 0;
    for (var i = 0; i < par.length; i++) {
      var bal = 0;
      for (var j = i; j < par.length; j++) {
        bal += par[j] == '(' ? 1 : -1;
        if (bal < 0) break;
        if (bal == 0) bestBal = max(bestBal, j - i + 1);
      }
    }
    expectEq('balanced', lbs.longestBalancedSubstring(par), bestBal, par);
    // palindrome min cuts brute
    final pstr = rs(8);
    bool isPal(String x) => x == x.split('').reversed.join();
    final memo = <int, int>{};
    int cuts(int i) => i == pstr.length
        ? -1
        : memo[i] ??= [
            for (var j = i + 1; j <= pstr.length; j++)
              if (isPal(pstr.substring(i, j))) 1 + cuts(j),
          ].reduce(min);
    if (pstr.isNotEmpty) expectEq('palCuts', ppmc.palindromePartitioningMinCuts(pstr), cuts(0), pstr);
    // longest palindromic substring length, longest substring w/o dup length
    if (pstr.isNotEmpty) {
      var bl = 0;
      for (var i = 0; i < pstr.length; i++)
        for (var j = i + 1; j <= pstr.length; j++) if (isPal(pstr.substring(i, j))) bl = max(bl, j - i);
      expectEq('lps', lps.longestPalindromicSubstring(pstr).length, bl, pstr);
      var bu = 0;
      for (var i = 0; i < pstr.length; i++)
        for (var j = i + 1; j <= pstr.length; j++)
          if (pstr.substring(i, j).split('').toSet().length == j - i) bu = max(bu, j - i);
      expectEq('lswd', lswd.longestSubstringWithoutDuplication(pstr).length, bu, pstr);
    }
    // max profit k transactions brute (DP over states small)
    final prices = randList(7, 1, 9);
    final k = rng.nextInt(3);
    int best(int day, int left, bool holding) {
      if (day == prices.length) return 0;
      var r = best(day + 1, left, holding);
      if (holding) r = max(r, prices[day] + best(day + 1, left, false));
      if (!holding && left > 0) r = max(r, -prices[day] + best(day + 1, left - 1, true));
      return r;
    }

    expectEq('maxProfitK', mpk.maxProfitWithKTransactions(prices, k), best(0, k, false), '$prices k=$k');
    // optimal assembly line brute
    final steps = randList(6, 1, 9);
    if (steps.isNotEmpty) {
      final st = 1 + rng.nextInt(steps.length);
      int bestSplit(int i, int stations) {
        if (i == steps.length) return 0;
        if (stations == 0) return 1 << 30;
        var r = 1 << 30, sum = 0;
        for (var j = i; j < steps.length; j++) {
          sum += steps[j];
          r = min(r, max(sum, bestSplit(j + 1, stations - 1)));
        }
        return r;
      }

      expectEq('assembly', oal.optimalAssemblyLine(steps, st), bestSplit(0, st), '$steps st=$st');
    }
    // longest subarray with sum (length), both versions
    final nn = randList(8, 0, 4);
    final tgt = rng.nextInt(8);
    var bestLen = -1;
    for (var i = 0; i < nn.length; i++) {
      var s = 0;
      for (var j = i; j < nn.length; j++) {
        s += nn[j];
        if (s == tgt) bestLen = max(bestLen, j - i + 1);
      }
    }
    List<int> r1 = lss.longestSubarrayWithSum(nn, tgt), r2 = lss.longestSubarrayWithSumAnySign(nn, tgt);
    expectEq('lssum', r1.isEmpty ? -1 : r1[1] - r1[0] + 1, bestLen, '$nn $tgt');
    expectEq('lssumAny', r2.isEmpty ? -1 : r2[1] - r2[0] + 1, bestLen, '$nn $tgt');
    // rectangles, squares, lines
    final pts = <List<int>>[];
    final seen = <String>{};
    for (var i = 0; i < rng.nextInt(9); i++) {
      final p = [rng.nextInt(4), rng.nextInt(4)];
      if (seen.add('$p')) pts.add(p);
    }
    var rects = 0, minArea = 0, squares = 0;
    final ps = {for (final p in pts) '$p'};
    for (var x1 = 0; x1 < 4; x1++)
      for (var x2 = x1 + 1; x2 < 4; x2++)
        for (var y1 = 0; y1 < 4; y1++)
          for (var y2 = y1 + 1; y2 < 4; y2++) {
            if (ps.containsAll(['[$x1, $y1]', '[$x1, $y2]', '[$x2, $y1]', '[$x2, $y2]'])) {
              rects++;
              final ar = (x2 - x1) * (y2 - y1);
              if (minArea == 0 || ar < minArea) minArea = ar;
            }
          }
    // squares any orientation brute: check all 4-subsets
    for (var i = 0; i < pts.length; i++)
      for (var j = i + 1; j < pts.length; j++)
        for (var k2 = j + 1; k2 < pts.length; k2++)
          for (var l = k2 + 1; l < pts.length; l++) {
            final q = [pts[i], pts[j], pts[k2], pts[l]];
            final dd = <int>[];
            for (var a2 = 0; a2 < 4; a2++)
              for (var b2 = a2 + 1; b2 < 4; b2++) {
                final dx = q[a2][0] - q[b2][0], dy = q[a2][1] - q[b2][1];
                dd.add(dx * dx + dy * dy);
              }
            dd.sort();
            if (dd[0] > 0 && dd[0] == dd[1] && dd[1] == dd[2] && dd[2] == dd[3] && dd[4] == dd[5] && dd[4] == 2 * dd[0])
              squares++;
          }
    expectEq('rectMania', rm.rectangleMania(pts), rects, pts);
    expectEq('minAreaRect', mar.minimumAreaRectangle(pts), minArea, pts);
    expectEq('countSquares', cs.countSquares(pts), squares, pts);
    var bestLine = min(pts.length, 2);
    for (var i = 0; i < pts.length; i++)
      for (var j = i + 1; j < pts.length; j++) {
        var c3 = 0;
        for (final p in pts) {
          if ((pts[j][0] - pts[i][0]) * (p[1] - pts[i][1]) == (pts[j][1] - pts[i][1]) * (p[0] - pts[i][0])) c3++;
        }
        bestLine = max(bestLine, c3);
      }
    expectEq('lineThrough', ltp.lineThroughPoints(pts), bestLine, pts);
    // next greater circular
    final ng = randList(7, 0, 5);
    expectEq('nge', nge.nextGreaterElement(ng), [
      for (var i = 0; i < ng.length; i++)
        () {
          for (var s = 1; s < ng.length; s++) {
            final v = ng[(i + s) % ng.length];
            if (v > ng[i]) return v;
          }
          return -1;
        }(),
    ], ng);
    // best digits brute
    final num = String.fromCharCodes(List.generate(1 + rng.nextInt(7), (_) => 48 + rng.nextInt(10)));
    final rem = rng.nextInt(num.length + 1);
    var bestNum = '';
    for (var mask = 0; mask < 1 << num.length; mask++) {
      var bits = 0;
      for (var i = 0; i < num.length; i++) if (mask & (1 << i) != 0) bits++;
      if (bits != rem) continue;
      final kept = [
        for (var i = 0; i < num.length; i++)
          if (mask & (1 << i) == 0) num[i],
      ].join();
      if (kept.compareTo(bestNum) > 0 || bestNum.isEmpty) bestNum = kept;
    }
    expectEq('bestDigits', bd.bestDigits(num, rem), bestNum, '$num rem=$rem');
    // dice throws brute
    final nd = rng.nextInt(4), sides = 1 + rng.nextInt(4), tg = rng.nextInt(10);
    int waysD(int dice, int left) => dice == 0
        ? (left == 0 ? 1 : 0)
        : [for (var f2 = 1; f2 <= sides; f2++) waysD(dice - 1, left - f2)].fold(0, (s, v) => s + v);
    expectEq('dice', dt.diceThrows(nd, sides, tg), waysD(nd, tg), '$nd $sides $tg');
    // juice bottling revenue
    final prices2 = [0, ...List.generate(rng.nextInt(7), (_) => rng.nextInt(12))];
    int bestRev(int u) => u == 0 ? 0 : [for (var s = 1; s <= u; s++) prices2[s] + bestRev(u - s)].reduce(max);
    final sizes = jb.juiceBottling(prices2);
    expectEq('juice', sizes.fold<int>(0, (s, v) => s + prices2[v]), bestRev(prices2.length - 1), prices2);
    expectEq('juice-total', sizes.fold<int>(0, (s, v) => s + v), prices2.length - 1, prices2);
    // square of zeroes brute
    final nsz = 1 + rng.nextInt(5);
    final mat = List.generate(nsz, (_) => List.generate(nsz, (_) => rng.nextInt(10) < 7 ? 0 : 1));
    var hasSq = false;
    for (var r = 0; r < nsz; r++)
      for (var c2 = 0; c2 < nsz; c2++)
        for (var sz2 = 2; r + sz2 <= nsz && c2 + sz2 <= nsz; sz2++) {
          var ok = true;
          for (var t2 = 0; t2 < sz2; t2++) {
            if (mat[r][c2 + t2] != 0 ||
                mat[r + sz2 - 1][c2 + t2] != 0 ||
                mat[r + t2][c2] != 0 ||
                mat[r + t2][c2 + sz2 - 1] != 0)
              ok = false;
          }
          if (ok) hasSq = true;
        }
    expectEq('squareZeroes', sz.squareOfZeroes(mat), hasSq, mat);
    // laptop rentals brute: max overlap at any time point
    final ints = List.generate(rng.nextInt(6), (_) {
      final s = rng.nextInt(10);
      return [s, s + 1 + rng.nextInt(5)];
    });
    var mo = 0;
    for (var tt = 0; tt < 20; tt++) {
      var c4 = 0;
      for (final iv in ints) if (iv[0] <= tt && tt < iv[1]) c4++;
      mo = max(mo, c4);
    }
    expectEq('laptops', lap.laptopRentals(ints), mo, ints);
    // spiral: permutation of all cells and first row matches
    final sp1 = sp.spiralTraverse(m);
    expectEq('spiral-perm', (sp1.toList()..sort()), List.generate(rows * cols, (i) => i), m);
    // DP classics
    final pos2 = randList(9, 1, 20);
    int msna(int i) => i >= pos2.length ? 0 : max(msna(i + 1), pos2[i] + msna(i + 2));
    expectEq('maxSubsetNoAdj', mssna.maxSubsetSumNoAdjacent(pos2), msna(0), pos2);
    final coins = distinct(3, 1, 7);
    final amt = rng.nextInt(15);
    final mcMemo = <int, int>{};
    int minC(int left) {
      if (left == 0) return 0;
      final cached = mcMemo[left];
      if (cached != null) return cached;
      var r = 1 << 20;
      for (final c5 in coins) if (c5 <= left) r = min(r, 1 + minC(left - c5));
      return mcMemo[left] = r;
    }

    final mc = coins.isEmpty ? (amt == 0 ? 0 : -1) : (minC(amt) >= 1 << 20 ? -1 : minC(amt));
    expectEq('minCoins', mnc.minNumberOfCoinsForChange(amt, coins), mc, '$amt $coins');
    final sortedCoins = [...coins]..sort();
    int ways(int idx, int left) {
      if (left == 0) return 1;
      if (idx == sortedCoins.length) return 0;
      var r = 0;
      for (var c6 = 0; c6 * sortedCoins[idx] <= left; c6++) r += ways(idx + 1, left - c6 * sortedCoins[idx]);
      return r;
    }

    expectEq('waysChange', nwc.numberOfWaysToMakeChange(amt, coins), ways(0, amt), '$amt $coins');
    final ex = randList(8, -9, 9);
    var bestEx = ex.length < 4 ? 0 : -(1 << 40);
    for (var i = 0; i < ex.length; i++)
      for (var j = i + 1; j < ex.length; j++)
        for (var k3 = j + 1; k3 < ex.length; k3++)
          for (var l = k3 + 1; l < ex.length; l++) bestEx = max(bestEx, ex[i] - ex[j] + ex[k3] - ex[l]);
    expectEq('maximizeExpr', mx.maximizeExpression(ex), bestEx, ex);
    if (ex.isNotEmpty) {
      var bk = ex[0];
      for (var i = 0; i < ex.length; i++) {
        var s = 0;
        for (var j = i; j < ex.length; j++) {
          s += ex[j];
          bk = max(bk, s);
        }
      }
      expectEq('kadane', kad.kadanesAlgorithm(ex), bk, ex);
      // max sum increasing subsequence brute
      var bm = -(1 << 40);
      for (var mask = 1; mask < 1 << ex.length; mask++) {
        final sub = [
          for (var i = 0; i < ex.length; i++)
            if (mask & (1 << i) != 0) ex[i],
        ];
        var ok = true;
        for (var i = 1; i < sub.length; i++) if (sub[i] <= sub[i - 1]) ok = false;
        if (ok) bm = max(bm, sub.fold(0, (s, v) => s + v));
      }
      expectEq('msis', msis.maxSumIncreasingSubsequence(ex)[0], bm, ex);
    }
    final sky = randList(8, 0, 6);
    var br = 0;
    for (var i = 0; i < sky.length; i++) {
      var mn = 1 << 30;
      for (var j = i; j < sky.length; j++) {
        mn = min(mn, sky[j]);
        br = max(br, mn * (j - i + 1));
      }
    }
    expectEq('skyline', lrus.largestRectangleUnderSkyline(sky), br, sky);
    // best seat brute: max min distance, lowest index
    final seats = [1, ...List.generate(rng.nextInt(8), (_) => rng.nextInt(2)), 1];
    var bsIdx = -1, bsD = 0;
    for (var i = 0; i < seats.length; i++) {
      if (seats[i] == 1) continue;
      var l = i;
      while (seats[l] == 0) l--;
      var r = i;
      while (seats[r] == 0) r++;
      final dd2 = min(i - l, r - i);
      if (dd2 > bsD) {
        bsD = dd2;
        bsIdx = i;
      }
    }
    expectEq('bestSeat', bs.bestSeat(seats), bsIdx, seats);
    // same BSTs brute: build trees and compare
    final arrA = randList(6, 0, 5);
    final arrB = rng.nextBool() ? ([...arrA]..shuffle(rng)) : randList(6, 0, 5);
    String shape(List<int> arr) {
      if (arr.isEmpty) return '-';
      final root = arr[0];
      return '($root ${shape([for (final x in arr.skip(1))
        if (x < root) x])} ${shape([for (final x in arr.skip(1))
        if (x >= root) x])})';
    }

    expectEq('sameBsts', sb.sameBsts(arrA, arrB), shape(arrA) == shape(arrB), '$arrA $arrB');
    // ambiguous measurements brute: enumerate multisets of pours (small)
    final cups = List.generate(1 + rng.nextInt(2), (_) {
      final lo2 = 1 + rng.nextInt(4);
      return [lo2, lo2 + rng.nextInt(3)];
    });
    final lowT = 1 + rng.nextInt(10), highT = lowT + rng.nextInt(5);
    var can = false;
    void rec(int idx, int lo2, int hi2) {
      if (lo2 >= lowT && hi2 <= highT && (lo2 > 0)) can = true;
      if (hi2 > highT || idx == cups.length) return;
      rec(idx, lo2 + cups[idx][0], hi2 + cups[idx][1]);
      rec(idx + 1, lo2, hi2);
    }

    rec(0, 0, 0);
    expectEq('ambiguous', am.ambiguousMeasurements(cups, lowT, highT), can, '$cups [$lowT,$highT]');
    // queens known counts
    // numbers in pi brute
    final piS = String.fromCharCodes(List.generate(1 + rng.nextInt(6), (_) => 49 + rng.nextInt(2)));
    final favs = <String>{
      for (var i = 0; i < 3; i++) String.fromCharCodes(List.generate(1 + rng.nextInt(3), (_) => 49 + rng.nextInt(2))),
    }.toList();
    int pieces(int i) {
      if (i == piS.length) return 0;
      var r = 1 << 20;
      for (final f3 in favs) if (piS.startsWith(f3, i)) r = min(r, 1 + pieces(i + f3.length));
      return r;
    }

    final pc = pieces(0);
    expectEq('numbersInPi', nip.numbersInPi(piS, favs), pc >= 1 << 20 ? -1 : pc - 1, '$piS $favs');
    bool buildable(String s) => s.isEmpty || favs.any((f4) => s.startsWith(f4) && buildable(s.substring(f4.length)));
    expectEq(
      'stringsMadeUp',
      smus.stringsMadeUpOfStrings([piS], favs),
      buildable(piS) ? [piS] : <String>[],
      '$piS $favs',
    );
    // dijkstra vs Floyd
    final nv = 1 + rng.nextInt(5);
    final edges = List.generate(nv, (_) => <List<int>>[]);
    final dmat = List.generate(nv, (i) => List.generate(nv, (j) => i == j ? 0 : 1 << 30));
    for (var i = 0; i < nv * 2; i++) {
      final u = rng.nextInt(nv), v = rng.nextInt(nv), w = rng.nextInt(10);
      if (u == v) continue;
      edges[u].add([v, w]);
      dmat[u][v] = min(dmat[u][v], w);
    }
    for (var kk = 0; kk < nv; kk++)
      for (var i = 0; i < nv; i++)
        for (var j = 0; j < nv; j++) if (dmat[i][kk] + dmat[kk][j] < dmat[i][j]) dmat[i][j] = dmat[i][kk] + dmat[kk][j];
    expectEq('dijkstra', dij.dijkstrasAlgorithm(0, edges), [
      for (final dd3 in dmat[0]) dd3 >= 1 << 30 ? -1 : dd3,
    ], edges);
    // two-edge-connected brute: connected and remains connected after removing each edge
    final und = List.generate(nv, (_) => <int>[]);
    final elist = <List<int>>[];
    for (var i = 0; i < nv * 2; i++) {
      final u = rng.nextInt(nv), v = rng.nextInt(nv);
      if (u == v || und[u].contains(v)) continue;
      und[u].add(v);
      und[v].add(u);
      elist.add([u, v]);
    }
    bool connected(List<int>? skip) {
      final vis = <int>{0};
      final st2 = [0];
      while (st2.isNotEmpty) {
        final u = st2.removeLast();
        for (final v in und[u]) {
          if (skip != null && ((skip[0] == u && skip[1] == v) || (skip[0] == v && skip[1] == u))) continue;
          if (vis.add(v)) st2.add(v);
        }
      }
      return vis.length == nv;
    }

    final tecWant = connected(null) && elist.every((e2) => connected(e2));
    expectEq('twoEdge', tec.twoEdgeConnectedGraph(und), tecWant, und);
    // airport connections brute: min k such that some k extra targets make all reachable
    final names = [for (var i = 0; i < nv; i++) 'A$i'];
    final routes = [
      for (var u = 0; u < nv; u++)
        for (final e3 in edges[u]) ['A$u', 'A${e3[0]}'],
    ];
    Set<int> reach(Set<int> starts) {
      final vis = {...starts};
      final st3 = [...starts];
      while (st3.isNotEmpty) {
        final u = st3.removeLast();
        for (final e4 in edges[u]) if (vis.add(e4[0])) st3.add(e4[0]);
      }
      return vis;
    }

    var bestK = nv;
    for (var mask = 0; mask < 1 << nv; mask++) {
      final starts = {
        0,
        for (var i = 0; i < nv; i++)
          if (mask & (1 << i) != 0) i,
      };
      var bitsK = 0;
      for (var i = 0; i < nv; i++) if (mask & (1 << i) != 0 && i != 0) bitsK++;
      if (reach(starts).length == nv) bestK = min(bestK, bitsK);
    }
    expectEq('airports', ac.airportConnections(names, routes, 'A0'), bestK, routes);
    // largest island (0 land, 1 water)
    final gi = List.generate(1 + rng.nextInt(4), (_) => List.generate(1 + rng.nextInt(1) + 2, (_) => rng.nextInt(2)));
    int biggest(List<List<int>> g2) {
      final R = g2.length, C = g2[0].length;
      final vis = <String>{};
      var bestI = 0;
      for (var r = 0; r < R; r++)
        for (var c7 = 0; c7 < C; c7++) {
          if (g2[r][c7] != 0 || vis.contains('$r,$c7')) continue;
          var size = 0;
          final st4 = [
            [r, c7],
          ];
          vis.add('$r,$c7');
          while (st4.isNotEmpty) {
            final p = st4.removeLast();
            size++;
            for (final dlt in [
              [1, 0],
              [-1, 0],
              [0, 1],
              [0, -1],
            ]) {
              final nr = p[0] + dlt[0], nc = p[1] + dlt[1];
              if (nr >= 0 && nr < R && nc >= 0 && nc < C && g2[nr][nc] == 0 && vis.add('$nr,$nc')) st4.add([nr, nc]);
            }
          }
          bestI = max(bestI, size);
        }
      return bestI;
    }

    var bestIsl = biggest(gi);
    for (var r = 0; r < gi.length; r++)
      for (var c8 = 0; c8 < gi[0].length; c8++)
        if (gi[r][c8] == 1) {
          final copy = [
            for (final row in gi) [...row],
          ];
          copy[r][c8] = 0;
          bestIsl = max(bestIsl, biggest(copy));
        }
    expectEq('largestIsland', li.largestIsland(gi), bestIsl, gi);
  }
  // longest string chain small brute
  for (var t = 0; t < 100; t++) {
    final words = <String>{
      for (var i = 0; i < 6; i++) String.fromCharCodes(List.generate(1 + rng.nextInt(4), (_) => 97 + rng.nextInt(2))),
    }.toList();
    final set = words.toSet();
    final memo = <String, int>{};
    int chain(String w) => memo[w] ??=
        1 +
        [
          0,
          for (var i = 0; i < w.length; i++)
            if (set.contains(w.substring(0, i) + w.substring(i + 1))) chain(w.substring(0, i) + w.substring(i + 1)),
        ].reduce(max);
    final bestC = words.map(chain).reduce(max);
    final got = lsc.longestStringChain(words);
    expectEq('stringChain-len', got.length, bestC >= 2 ? bestC : 0, words);
    for (var i = 1; i < got.length; i++) {
      final a2 = got[i - 1], b2 = got[i];
      final okStep =
          a2.length == b2.length + 1 &&
          [for (var j = 0; j < a2.length; j++) a2.substring(0, j) + a2.substring(j + 1)].contains(b2);
      expectEq('stringChain-step', okStep, true, got);
    }
  }
  expectEq('queens', [for (var n = 1; n <= 9; n++) naq.nonAttackingQueens(n)], [1, 0, 0, 2, 10, 4, 40, 92, 352], 'n');
  print(failures == 0 ? 'ALL STRESS TESTS PASSED' : 'failures: $failures');
  if (failures > 0) exitCode = 1;
}
