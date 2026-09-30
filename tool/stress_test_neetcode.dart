// Randomized cross-checks for the neetcode/ set: compares solutions against independent,
// deliberately naive brute forces on random small inputs. Run: dart run tool/stress_test_neetcode.dart

import 'dart:io';
import 'dart:math';
import '../neetcode/01_contains_duplicate/contains_duplicate.dart' as n01;
import '../neetcode/02_valid_anagram/valid_anagram.dart' as n02;
import '../neetcode/03_encode_and_decode_strings/encode_and_decode_strings.dart' as n03;
import '../neetcode/04_valid_sudoku/valid_sudoku.dart' as n04;
import '../neetcode/05_valid_palindrome/valid_palindrome.dart' as n05;
import '../neetcode/06_permutation_in_string/permutation_in_string.dart' as n06;
import '../neetcode/07_daily_temperatures/daily_temperatures.dart' as n07;
import '../neetcode/09_search_a_2d_matrix/search_a_2d_matrix.dart' as n09;
import '../neetcode/10_time_based_key_value_store/time_based_key_value_store.dart' as n10;
import '../neetcode/11_merge_k_sorted_lists/merge_k_sorted_lists.dart' as n11;
import '../neetcode/12_maximum_depth_of_binary_tree/maximum_depth_of_binary_tree.dart' as n12;
import '../neetcode/13_same_tree/same_tree.dart' as n13;
import '../neetcode/14_subtree_of_another_tree/subtree_of_another_tree.dart' as n14;
import '../neetcode/16_binary_tree_level_order_traversal/binary_tree_level_order_traversal.dart' as n16;
import '../neetcode/17_binary_tree_right_side_view/binary_tree_right_side_view.dart' as n17;
import '../neetcode/18_count_good_nodes_in_binary_tree/count_good_nodes_in_binary_tree.dart' as n18;
import '../neetcode/19_implement_trie/implement_trie.dart' as n19;
import '../neetcode/20_design_add_and_search_words/design_add_and_search_words.dart' as n20;
import '../neetcode/21_kth_largest_element_in_a_stream/kth_largest_element_in_a_stream.dart' as n21;
import '../neetcode/22_last_stone_weight/last_stone_weight.dart' as n22;
import '../neetcode/23_k_closest_points_to_origin/k_closest_points_to_origin.dart' as n23;
import '../neetcode/25_combination_sum_ii/combination_sum_ii.dart' as n25;
import '../neetcode/27_pacific_atlantic_water_flow/pacific_atlantic_water_flow.dart' as n27;
import '../neetcode/28_walls_and_gates/walls_and_gates.dart' as n28;
import '../neetcode/29_redundant_connection/redundant_connection.dart' as n29;
import '../neetcode/30_graph_valid_tree/graph_valid_tree.dart' as n30;
import '../neetcode/31_reconstruct_itinerary/reconstruct_itinerary.dart' as n31;
import '../neetcode/32_swim_in_rising_water/swim_in_rising_water.dart' as n32;
import '../neetcode/33_min_cost_climbing_stairs/min_cost_climbing_stairs.dart' as n33;
import '../neetcode/34_house_robber_ii/house_robber_ii.dart' as n34;
import '../neetcode/35_palindromic_substrings/palindromic_substrings.dart' as n35;
import '../neetcode/36_decode_ways/decode_ways.dart' as n36;
import '../neetcode/37_word_break/word_break.dart' as n37;
import '../neetcode/38_best_time_to_buy_and_sell_stock_with_cooldown/best_time_to_buy_and_sell_stock_with_cooldown.dart'
    as n38;
import '../neetcode/39_target_sum/target_sum.dart' as n39;
import '../neetcode/40_longest_increasing_path_in_a_matrix/longest_increasing_path_in_a_matrix.dart' as n40;
import '../neetcode/41_regular_expression_matching/regular_expression_matching.dart' as n41;
import '../neetcode/42_jump_game/jump_game.dart' as n42;
import '../neetcode/43_hand_of_straights/hand_of_straights.dart' as n43;
import '../neetcode/44_merge_triplets_to_form_target_triplet/merge_triplets_to_form_target_triplet.dart' as n44;
import '../neetcode/45_partition_labels/partition_labels.dart' as n45;
import '../neetcode/46_insert_interval/insert_interval.dart' as n46;
import '../neetcode/47_meeting_rooms/meeting_rooms.dart' as n47;
import '../neetcode/48_minimum_interval_to_include_each_query/minimum_interval_to_include_each_query.dart' as n48;
import '../neetcode/49_happy_number/happy_number.dart' as n49;
import '../neetcode/50_plus_one/plus_one.dart' as n50;
import '../neetcode/51_pow_x_n/pow_x_n.dart' as n51;
import '../neetcode/52_multiply_strings/multiply_strings.dart' as n52;
import '../neetcode/53_detect_squares/detect_squares.dart' as n53;
import '../neetcode/55_number_of_1_bits/number_of_1_bits.dart' as n55;
import '../neetcode/56_counting_bits/counting_bits.dart' as n56;
import '../neetcode/57_reverse_bits/reverse_bits.dart' as n57;
import '../neetcode/58_missing_number/missing_number.dart' as n58;
import '../neetcode/59_sum_of_two_integers/sum_of_two_integers.dart' as n59;
import '../neetcode/60_reverse_integer/reverse_integer.dart' as n60;

final rng = Random(21);
var failures = 0;
void expectEq(String name, Object? got, Object? want, Object? input) {
  if ('$got' != '$want') {
    failures++;
    if (failures < 30) print('FAIL $name input=$input got=$got want=$want');
  }
}

List<int> randList(int minLen, int maxLen, int lo, int hi) =>
    List.generate(minLen + rng.nextInt(maxLen - minLen + 1), (_) => lo + rng.nextInt(hi - lo + 1));
String randWord(int minLen, int maxLen, String alphabet) =>
    [for (var i = 0; i < minLen + rng.nextInt(maxLen - minLen + 1); i++) alphabet[rng.nextInt(alphabet.length)]].join();

/// A random binary tree shape, converted into each solution's own TreeNode class.
class Shape {
  Shape(this.$1, this.$2, this.$3);
  final int $1;
  final Shape? $2, $3;
  @override
  String toString() => '(${$1}, ${$2}, ${$3})';
}

Shape? randTree(int size) {
  if (size == 0) return null;
  final leftSize = rng.nextInt(size);
  return Shape(rng.nextInt(7) - 3, randTree(leftSize), randTree(size - 1 - leftSize));
}

void main() {
  arrays();
  trees();
  heapsAndDesign();
  graphs();
  dp();
  greedyIntervalsMath();
  print(failures == 0 ? 'ALL NEETCODE STRESS TESTS PASSED' : 'failures: $failures');
  if (failures > 0) exitCode = 1;
}

void arrays() {
  for (var t = 0; t < 300; t++) {
    final a = randList(0, 8, 0, 9);
    expectEq('01 dup', n01.containsDuplicate(a), a.toSet().length != a.length, a);
    final s = randWord(0, 6, 'abc'), u = randWord(0, 6, 'abc');
    expectEq('02 anagram', n02.isAnagram(s, u), (s.split('')..sort()).join() == (u.split('')..sort()).join(), (s, u));
    final strs = [for (var i = 0; i < rng.nextInt(5); i++) randWord(0, 5, 'a#1 ')];
    expectEq('03 roundtrip', n03.decode(n03.encode(strs)), strs, strs);
    final p = randWord(0, 8, 'aA,b 0.');
    final cleaned = p.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    expectEq('05 palindrome', n05.isPalindrome(p), cleaned == cleaned.split('').reversed.join(), p);
    final s1 = randWord(1, 3, 'abc'), s2 = randWord(0, 8, 'abc');
    final key = (s1.split('')..sort()).join();
    var want6 = false;
    for (var i = 0; i + s1.length <= s2.length; i++) {
      if ((s2.substring(i, i + s1.length).split('')..sort()).join() == key) want6 = true;
    }
    expectEq('06 permutation', n06.checkInclusion(s1, s2), want6, (s1, s2));
    final temps = randList(0, 9, 30, 35);
    expectEq('07 daily', n07.dailyTemperatures(temps), [
      for (var i = 0; i < temps.length; i++)
        () {
          for (var j = i + 1; j < temps.length; j++) {
            if (temps[j] > temps[i]) return j - i;
          }
          return 0;
        }(),
    ], temps);
    final r = 1 + rng.nextInt(3), c = 1 + rng.nextInt(3);
    final flat = randList(r * c, r * c, 0, 20)..sort();
    final m = [for (var i = 0; i < r; i++) flat.sublist(i * c, i * c + c)];
    final target = rng.nextInt(22);
    expectEq('09 matrix', n09.searchMatrix(m, target), flat.contains(target), (m, target));
  }
  // 04 sudoku: random sparse boards, brute check of every row, column and box.
  for (var t = 0; t < 300; t++) {
    final cells = List.generate(9, (_) => List.filled(9, '.'));
    for (var k = 0; k < 6 + rng.nextInt(10); k++) {
      cells[rng.nextInt(9)][rng.nextInt(9)] = '${1 + rng.nextInt(9)}';
    }
    bool ok(List<String> group) {
      final digits = group.where((x) => x != '.').toList();
      return digits.toSet().length == digits.length;
    }

    var valid = true;
    for (var i = 0; i < 9; i++) {
      valid &= ok(cells[i]);
      valid &= ok([for (var r = 0; r < 9; r++) cells[r][i]]);
      final br = (i ~/ 3) * 3, bc = (i % 3) * 3;
      valid &= ok([
        for (var r = br; r < br + 3; r++)
          for (var c = bc; c < bc + 3; c++) cells[r][c],
      ]);
    }
    final board = [for (final row in cells) row.join()];
    expectEq('04 sudoku', n04.isValidSudoku(board), valid, board);
  }
  // 10 time map vs a linear scan.
  for (var t = 0; t < 100; t++) {
    final tm = n10.TimeMap();
    final log = <(String, int, String)>[];
    var time = 0;
    for (var op = 0; op < 20; op++) {
      final key = 'k${rng.nextInt(3)}';
      if (rng.nextBool()) {
        time += 1 + rng.nextInt(3);
        final v = 'v$op';
        tm.set(key, v, time);
        log.add((key, time, v));
      } else {
        final q = rng.nextInt(time + 3);
        var want = '';
        for (final (k, ts, v) in log) {
          if (k == key && ts <= q) want = v;
        }
        expectEq('10 timemap', tm.get(key, q), want, (key, q));
      }
    }
  }
  // 11 merge k lists vs sorting.
  for (var t = 0; t < 200; t++) {
    final lists = [for (var i = 0; i < rng.nextInt(5); i++) randList(0, 5, -5, 5)..sort()];
    final want = [for (final l in lists) ...l]..sort();
    expectEq('11 mergeK heap', n11.toList(n11.mergeKLists([for (final l in lists) n11.fromList(l)])), want, lists);
    expectEq(
      '11 mergeK pairwise',
      n11.toList(n11.mergeKListsPairwise([for (final l in lists) n11.fromList(l)])),
      want,
      lists,
    );
  }
}

void trees() {
  for (var t = 0; t < 300; t++) {
    final shape = randTree(rng.nextInt(10));
    n12.TreeNode? t12(Shape? s) => s == null ? null : n12.TreeNode(s.$1, t12(s.$2), t12(s.$3));
    n13.TreeNode? t13(Shape? s) => s == null ? null : n13.TreeNode(s.$1, t13(s.$2), t13(s.$3));
    n14.TreeNode? t14(Shape? s) => s == null ? null : n14.TreeNode(s.$1, t14(s.$2), t14(s.$3));
    n16.TreeNode? t16(Shape? s) => s == null ? null : n16.TreeNode(s.$1, t16(s.$2), t16(s.$3));
    n17.TreeNode? t17(Shape? s) => s == null ? null : n17.TreeNode(s.$1, t17(s.$2), t17(s.$3));
    n18.TreeNode? t18(Shape? s) => s == null ? null : n18.TreeNode(s.$1, t18(s.$2), t18(s.$3));

    // Brute: (depth, value) pairs in preorder, and root-to-node paths.
    final byDepth = <int, List<int>>{};
    var good = 0;
    void walk(Shape? s, int depth, List<int> path) {
      if (s == null) return;
      byDepth.putIfAbsent(depth, () => []).add(s.$1); // preorder visits each level left to right
      if (path.every((v) => v <= s.$1)) good++;
      walk(s.$2, depth + 1, [...path, s.$1]);
      walk(s.$3, depth + 1, [...path, s.$1]);
    }

    walk(shape, 0, []);
    final levels = [for (var d = 0; d < byDepth.length; d++) byDepth[d]!];
    expectEq('12 depth', n12.maxDepth(t12(shape)), levels.length, shape);
    expectEq('12 depth bfs', n12.maxDepthBfs(t12(shape)), levels.length, shape);
    expectEq('16 level order', n16.levelOrder(t16(shape)), levels, shape);
    expectEq('17 right view', n17.rightSideView(t17(shape)), [for (final l in levels) l.last], shape);
    if (shape != null) expectEq('18 good nodes', n18.goodNodes(t18(shape)!), good, shape);

    final other = rng.nextInt(3) == 0 ? shape : randTree(rng.nextInt(4));
    expectEq('13 same', n13.isSameTree(t13(shape), t13(other)), '$shape' == '$other', (shape, other));
    // Subtree brute: compare the printed shape of every subtree.
    final subs = <String>{};
    void collect(Shape? s) {
      if (s == null) return;
      subs.add('$s');
      collect(s.$2);
      collect(s.$3);
    }

    collect(shape);
    final sub = randTree(1 + rng.nextInt(2));
    expectEq('14 subtree', n14.isSubtree(t14(shape), t14(sub)), subs.contains('$sub'), (shape, sub));
  }
}

void heapsAndDesign() {
  for (var t = 0; t < 100; t++) {
    // 19 trie and 20 wildcard search vs a plain list of words.
    final trie = n19.Trie(), dict = n20.WordDictionary();
    final words = <String>{};
    for (var op = 0; op < 20; op++) {
      final w = randWord(1, 3, 'ab'); // LeetCode words and prefixes are non-empty
      switch (rng.nextInt(4)) {
        case 0:
          trie.insert(w);
          dict.addWord(w);
          words.add(w);
        case 1:
          expectEq('19 search', trie.search(w), words.contains(w), w);
        case 2:
          expectEq('19 startsWith', trie.startsWith(w), words.any((x) => x.startsWith(w)), w);
        default:
          final pattern = w.split('').map((ch) => rng.nextBool() ? '.' : ch).join();
          final re = RegExp('^$pattern\$');
          expectEq('20 search', dict.search(pattern), words.any(re.hasMatch), pattern);
      }
    }
    // 21 kth largest vs sorting.
    final k = 1 + rng.nextInt(3);
    final init = randList(k - 1, 5, -5, 5);
    final kth = n21.KthLargest(k, init);
    final all = [...init];
    for (var op = 0; op < 10; op++) {
      final v = rng.nextInt(11) - 5;
      all.add(v);
      expectEq('21 kth', kth.add(v), (all.toList()..sort((a, b) => b - a))[k - 1], (k, all));
    }
  }
  for (var t = 0; t < 300; t++) {
    // 22 last stone via repeated sorting.
    final stones = randList(1, 8, 1, 10);
    final s = [...stones];
    while (s.length > 1) {
      s.sort();
      final y = s.removeLast(), x = s.removeLast();
      if (y != x) s.add(y - x);
    }
    expectEq('22 stone', n22.lastStoneWeight(stones), s.isEmpty ? 0 : s.first, stones);
    // 23 k closest: compare the multiset of distances.
    final pts = [
      for (var i = 0; i < 1 + rng.nextInt(7); i++) [rng.nextInt(7) - 3, rng.nextInt(7) - 3],
    ];
    final k = 1 + rng.nextInt(pts.length);
    int d(List<int> p) => p[0] * p[0] + p[1] * p[1];
    expectEq(
      '23 closest',
      n23.kClosest(pts, k).map(d).toList()..sort(),
      (pts.map(d).toList()..sort()).take(k).toList(),
      (pts, k),
    );
    // 25 combination sum II vs bitmask over distinct sorted picks.
    final cands = randList(0, 7, 1, 4);
    final target = 1 + rng.nextInt(8);
    final want = <String>{};
    for (var mask = 0; mask < 1 << cands.length; mask++) {
      final pick = [
        for (var i = 0; i < cands.length; i++)
          if (mask & (1 << i) != 0) cands[i],
      ]..sort();
      if (pick.fold(0, (a, b) => a + b) == target) want.add('$pick');
    }
    final got = n25.combinationSum2(cands, target).map((c) => '$c').toList();
    expectEq('25 combo II', got..sort(), want.toList()..sort(), (cands, target));
  }
}

void graphs() {
  for (var t = 0; t < 200; t++) {
    final r = 1 + rng.nextInt(4), c = 1 + rng.nextInt(4);
    final h = [for (var i = 0; i < r; i++) randList(c, c, 0, 4)];
    // 27: from each cell, flood downhill (<=) and see which oceans are touched.
    final want27 = <List<int>>[];
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        final seen = <int>{i * c + j};
        final stack = [(i, j)];
        var pac = false, atl = false;
        while (stack.isNotEmpty) {
          final (x, y) = stack.removeLast();
          if (x == 0 || y == 0) pac = true;
          if (x == r - 1 || y == c - 1) atl = true;
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= r || ny >= c || h[nx][ny] > h[x][y]) continue;
            if (seen.add(nx * c + ny)) stack.add((nx, ny));
          }
        }
        if (pac && atl) want27.add([i, j]);
      }
    }
    expectEq('27 pacific', n27.pacificAtlantic(h), want27, h);

    // 28: BFS from every room separately.
    final grid = [
      for (var i = 0; i < r; i++)
        [
          for (var j = 0; j < c; j++) [-1, 0, n28.inf, n28.inf][rng.nextInt(4)],
        ],
    ];
    final want28 = [
      for (var i = 0; i < r; i++)
        [
          for (var j = 0; j < c; j++)
            grid[i][j] != n28.inf
                ? grid[i][j]
                : () {
                    final dist = {i * c + j: 0};
                    final queue = [(i, j)];
                    for (var q = 0; q < queue.length; q++) {
                      final (x, y) = queue[q];
                      if (grid[x][y] == 0) return dist[x * c + y]!;
                      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
                        final nx = x + dx, ny = y + dy;
                        if (nx < 0 || ny < 0 || nx >= r || ny >= c || grid[nx][ny] == -1) continue;
                        if (!dist.containsKey(nx * c + ny)) {
                          dist[nx * c + ny] = dist[x * c + y]! + 1;
                          queue.add((nx, ny));
                        }
                      }
                    }
                    return n28.inf;
                  }(),
        ],
    ];
    final g28 = [
      for (final row in grid) [...row],
    ];
    n28.wallsAndGates(g28);
    expectEq('28 walls', g28, want28, grid);

    // 40: plain DFS without memo.
    int longest(int x, int y) {
      var best = 1;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < r && ny < c && h[nx][ny] > h[x][y]) best = max(best, 1 + longest(nx, ny));
      }
      return best;
    }

    var want40 = 0;
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        want40 = max(want40, longest(i, j));
      }
    }
    expectEq('40 LIP', n40.longestIncreasingPath(h), want40, h);

    // 32: smallest t such that BFS over cells <= t connects the corners.
    final n = 1 + rng.nextInt(4);
    final perm = List.generate(n * n, (i) => i)..shuffle(rng);
    final g32 = [for (var i = 0; i < n; i++) perm.sublist(i * n, i * n + n)];
    var want32 = 0;
    while (true) {
      if (g32[0][0] <= want32) {
        final seen = <int>{0};
        final stack = [(0, 0)];
        while (stack.isNotEmpty) {
          final (x, y) = stack.removeLast();
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= n || ny >= n || g32[nx][ny] > want32) continue;
            if (seen.add(nx * n + ny)) stack.add((nx, ny));
          }
        }
        if (seen.contains(n * n - 1)) break;
      }
      want32++;
    }
    expectEq('32 swim', n32.swimInWater(g32), want32, g32);
  }

  // 29, 30: random trees plus possibly one extra edge.
  for (var t = 0; t < 200; t++) {
    final n = 1 + rng.nextInt(6);
    final edges = <List<int>>[
      for (var v = 1; v < n; v++) [rng.nextInt(v), v],
    ];
    if (rng.nextBool() && n > 1) edges.removeAt(rng.nextInt(edges.length)); // maybe disconnect
    if (rng.nextBool()) edges.add([rng.nextInt(n), rng.nextInt(n)]); // maybe add a cycle
    edges.shuffle(rng);
    bool isTree(int n, List<List<int>> es) {
      if (es.length != n - 1) return false;
      final adj = List.generate(n, (_) => <int>[]);
      for (final e in es) {
        adj[e[0]].add(e[1]);
        adj[e[1]].add(e[0]);
      }
      final seen = <int>{0};
      final stack = [0];
      while (stack.isNotEmpty) {
        for (final w in adj[stack.removeLast()]) {
          if (seen.add(w)) stack.add(w);
        }
      }
      return seen.length == n;
    }

    expectEq('30 valid tree', n30.validTree(n, edges), isTree(n, edges), (n, edges));

    // 29 on 1-indexed tree + one extra edge (no self loops): the answer is the last edge whose
    // removal leaves a tree.
    final m = 3 + rng.nextInt(4);
    final tree = <List<int>>[
      for (var v = 2; v <= m; v++) [1 + rng.nextInt(v - 1), v],
    ];
    int a, b;
    do {
      a = 1 + rng.nextInt(m);
      b = 1 + rng.nextInt(m);
    } while (a == b || tree.any((e) => (e[0] == a && e[1] == b) || (e[0] == b && e[1] == a)));
    final all = [
      ...tree,
      a < b ? [a, b] : [b, a],
    ]..shuffle(rng);
    List<int>? want29;
    for (var i = all.length - 1; i >= 0 && want29 == null; i--) {
      final rest = [...all]..removeAt(i);
      if (isTree(m, [
        for (final e in rest) [e[0] - 1, e[1] - 1],
      ])) {
        want29 = all[i];
      }
    }
    expectEq('29 redundant', n29.findRedundantConnection(all), want29, all);
  }

  // 31 itinerary: backtracking over destinations in sorted order returns the smallest valid route.
  for (var t = 0; t < 200; t++) {
    const airports = ['JFK', 'AAA', 'BBB', 'CCC'];
    // Build a random walk from JFK so a valid itinerary always exists.
    final tickets = <List<String>>[];
    var at = 'JFK';
    for (var i = 0; i < 1 + rng.nextInt(6); i++) {
      final to = airports[rng.nextInt(4)];
      tickets.add([at, to]);
      at = to;
    }
    final sortedTickets = [...tickets]..sort((x, y) => '${x[1]}'.compareTo(y[1]));
    final used = List.filled(sortedTickets.length, false);
    List<String>? route;
    bool go(List<String> path) {
      if (path.length == sortedTickets.length + 1) {
        route = [...path];
        return true;
      }
      for (var i = 0; i < sortedTickets.length; i++) {
        if (used[i] || sortedTickets[i][0] != path.last) continue;
        used[i] = true;
        if (go([...path, sortedTickets[i][1]])) return true;
        used[i] = false;
      }
      return false;
    }

    go(['JFK']);
    expectEq('31 itinerary', n31.findItinerary(tickets.map((e) => [...e]).toList()), route, tickets);
  }
}

void dp() {
  for (var t = 0; t < 300; t++) {
    final cost = randList(2, 8, 0, 9);
    int climb(int i) => i >= cost.length ? 0 : cost[i] + min(climb(i + 1), climb(i + 2));
    expectEq('33 stairs', n33.minCostClimbingStairs(cost), min(climb(0), climb(1)), cost);

    final houses = randList(1, 8, 0, 9);
    var best34 = 0;
    for (var mask = 0; mask < 1 << houses.length; mask++) {
      var ok = true, sum = 0;
      for (var i = 0; i < houses.length; i++) {
        if (mask & (1 << i) == 0) continue;
        final next = (i + 1) % houses.length;
        if (houses.length > 1 && mask & (1 << next) != 0) ok = false;
        sum += houses[i];
      }
      if (ok) best34 = max(best34, sum);
    }
    expectEq('34 robber II', n34.rob(houses), best34, houses);

    final s = randWord(0, 8, 'ab');
    var pal = 0;
    for (var i = 0; i < s.length; i++) {
      for (var j = i + 1; j <= s.length; j++) {
        final sub = s.substring(i, j);
        if (sub == sub.split('').reversed.join()) pal++;
      }
    }
    expectEq('35 palindromic', n35.countSubstrings(s), pal, s);

    final digits = randWord(1, 7, '01267');
    int decode(int i) {
      if (i == digits.length) return 1;
      if (digits[i] == '0') return 0;
      var ways = decode(i + 1);
      if (i + 1 < digits.length && int.parse(digits.substring(i, i + 2)) <= 26) ways += decode(i + 2);
      return ways;
    }

    expectEq('36 decode', n36.numDecodings(digits), decode(0), digits);

    final dict = [for (var i = 0; i < 1 + rng.nextInt(3); i++) randWord(1, 3, 'ab')];
    final text = randWord(0, 8, 'ab');
    bool breakable(int i) => i == text.length || dict.any((w) => text.startsWith(w, i) && breakable(i + w.length));
    expectEq('37 word break', n37.wordBreak(text, dict), breakable(0), (text, dict));

    final prices = randList(1, 8, 0, 9);
    // state: 0 = free to buy, 1 = holding, 2 = cooldown
    int trade(int day, int state) {
      if (day == prices.length) return 0;
      final p = prices[day];
      return switch (state) {
        0 => max(trade(day + 1, 0), trade(day + 1, 1) - p),
        1 => max(trade(day + 1, 1), trade(day + 1, 2) + p),
        _ => trade(day + 1, 0),
      };
    }

    expectEq('38 cooldown', n38.maxProfit(prices), trade(0, 0), prices);

    final nums = randList(1, 7, 0, 3);
    final tgt = rng.nextInt(9) - 4;
    int signs(int i, int sum) =>
        i == nums.length ? (sum == tgt ? 1 : 0) : signs(i + 1, sum + nums[i]) + signs(i + 1, sum - nums[i]);
    expectEq('39 target sum', n39.findTargetSumWays(nums, tgt), signs(0, 0), (nums, tgt));

    final str = randWord(0, 5, 'ab');
    var pat = '';
    for (var i = 0; i < rng.nextInt(5); i++) {
      pat += 'ab.'[rng.nextInt(3)];
      if (rng.nextBool()) pat += '*';
    }
    expectEq('41 regex', n41.isMatch(str, pat), RegExp('^(?:$pat)\$').hasMatch(str), (str, pat));
  }
}

void greedyIntervalsMath() {
  for (var t = 0; t < 300; t++) {
    final jumps = randList(1, 7, 0, 3);
    final reach = {0};
    for (var i = 0; i < jumps.length; i++) {
      if (!reach.contains(i)) continue;
      for (var j = 1; j <= jumps[i]; j++) {
        reach.add(i + j);
      }
    }
    expectEq('42 jump', n42.canJump(jumps), reach.contains(jumps.length - 1), jumps);

    final hand = randList(0, 8, 1, 5);
    final g = 1 + rng.nextInt(3);
    bool split(List<int> cards) {
      if (cards.isEmpty) return true;
      final rest = [...cards]..sort();
      final start = rest.first;
      for (var v = start; v < start + g; v++) {
        if (!rest.remove(v)) return false;
      }
      return split(rest);
    }

    expectEq('43 hand', n43.isNStraightHand(hand, g), hand.length % g == 0 && split(hand), (hand, g));

    final triplets = [for (var i = 0; i < rng.nextInt(5); i++) randList(3, 3, 1, 4)];
    final target = randList(3, 3, 1, 4);
    var can44 = false;
    for (var mask = 1; mask < 1 << triplets.length; mask++) {
      final merged = [0, 0, 0];
      for (var i = 0; i < triplets.length; i++) {
        if (mask & (1 << i) == 0) continue;
        for (var k = 0; k < 3; k++) {
          merged[k] = max(merged[k], triplets[i][k]);
        }
      }
      if ('$merged' == '$target') can44 = true;
    }
    expectEq('44 triplets', n44.mergeTriplets(triplets, target), can44, (triplets, target));

    // 45: a cut after i is allowed iff no letter appears on both sides; take every allowed cut.
    final s = randWord(1, 9, 'abcd');
    final sizes = <int>[];
    var start = 0;
    for (var i = 0; i < s.length; i++) {
      final left = s.substring(0, i + 1).split('').toSet(), right = s.substring(i + 1).split('').toSet();
      if (left.intersection(right).isEmpty) {
        sizes.add(i + 1 - start);
        start = i + 1;
      }
    }
    expectEq('45 labels', n45.partitionLabels(s), sizes, s);

    // 46 insert: add the interval and merge everything from scratch.
    final ivs = <List<int>>[];
    var pos = rng.nextInt(3);
    for (var i = 0; i < rng.nextInt(5); i++) {
      final a = pos, b = a + rng.nextInt(3);
      ivs.add([a, b]);
      pos = b + 1 + rng.nextInt(3);
    }
    final lo = rng.nextInt(15);
    final ins = [lo, lo + rng.nextInt(5)];
    final all = [...ivs, ins]..sort((x, y) => x[0].compareTo(y[0]));
    final merged = <List<int>>[];
    for (final iv in all) {
      if (merged.isNotEmpty && iv[0] <= merged.last[1]) {
        merged.last[1] = max(merged.last[1], iv[1]);
      } else {
        merged.add([...iv]);
      }
    }
    expectEq('46 insert', n46.insert(ivs, ins), merged, (ivs, ins));

    final meetings = [
      for (var i = 0; i < rng.nextInt(5); i++) [rng.nextInt(10), 0],
    ];
    for (final m in meetings) {
      m[1] = m[0] + 1 + rng.nextInt(3);
    }
    var free = true;
    for (var i = 0; i < meetings.length; i++) {
      for (var j = i + 1; j < meetings.length; j++) {
        if (meetings[i][0] < meetings[j][1] && meetings[j][0] < meetings[i][1]) free = false;
      }
    }
    expectEq('47 meetings', n47.canAttendMeetings(meetings), free, meetings);

    final intervals = [
      for (var i = 0; i < 1 + rng.nextInt(5); i++) [rng.nextInt(10), 0],
    ];
    for (final iv in intervals) {
      iv[1] = iv[0] + rng.nextInt(5);
    }
    final queries = randList(1, 5, 0, 14);
    expectEq(
      '48 min interval',
      n48.minInterval(intervals, queries),
      [
        for (final q in queries)
          intervals.where((iv) => iv[0] <= q && q <= iv[1]).map((iv) => iv[1] - iv[0] + 1).fold(-1, (best, size) {
            return best == -1 || size < best ? size : best;
          }),
      ],
      (intervals, queries),
    );
  }

  // Math and bits.
  for (var n = 1; n <= 500; n++) {
    final seen = <int>{};
    var x = n;
    while (x != 1 && seen.add(x)) {
      x = x.toString().split('').map(int.parse).fold(0, (a, d) => a + d * d);
    }
    expectEq('49 happy', n49.isHappy(n), x == 1, n);
  }
  for (var t = 0; t < 300; t++) {
    final digits = [1 + rng.nextInt(9), ...randList(0, 6, 0, 9)];
    if (rng.nextInt(4) == 0) digits.fillRange(0, digits.length, 9);
    final want50 = (BigInt.parse(digits.join()) + BigInt.one).toString().split('').map(int.parse).toList();
    expectEq('50 plus one', n50.plusOne(digits), want50, digits);

    final base = (rng.nextInt(41) - 20) / 10, e = rng.nextInt(21) - 10;
    final want51 = pow(base, e).toDouble();
    final got51 = n51.myPow(base, e);
    final close =
        got51 == want51 || (got51 - want51).abs() <= 1e-9 * max(1, want51.abs()) || (got51.isNaN && want51.isNaN);
    expectEq('51 pow', close, true, (base, e, got51, want51));

    final a = randWord(1, 8, '0123456789'), b = randWord(1, 8, '0123456789');
    final na = BigInt.parse(a).toString(), nb = BigInt.parse(b).toString(); // strip leading zeros
    expectEq('52 multiply', n52.multiply(na, nb), (BigInt.parse(na) * BigInt.parse(nb)).toString(), (na, nb));

    final x = rng.nextInt(1 << 31);
    expectEq('55 popcount', n55.hammingWeight(x), x.toRadixString(2).replaceAll('0', '').length, x);
    expectEq(
      '57 reverse bits',
      n57.reverseBits(x),
      int.parse(x.toRadixString(2).padLeft(32, '0').split('').reversed.join(), radix: 2),
      x,
    );
    final nMiss = rng.nextInt(8);
    final missing = rng.nextInt(nMiss + 1);
    final arr = [
      for (var i = 0; i <= nMiss; i++)
        if (i != missing) i,
    ]..shuffle(rng);
    expectEq('58 missing', n58.missingNumber(arr), missing, arr);
    final p = rng.nextInt(2001) - 1000, q = rng.nextInt(2001) - 1000;
    expectEq('59 sum', n59.getSum(p, q), p + q, (p, q));
    final v = rng.nextInt(1 << 32) - (1 << 31);
    final digitsRev = int.parse(v.abs().toString().split('').reversed.join()) * (v < 0 ? -1 : 1);
    final want60 = digitsRev > 2147483647 || digitsRev < -2147483648 ? 0 : digitsRev;
    expectEq('60 reverse int', n60.reverse(v), want60, v);
  }
  expectEq('56 counting bits', n56.countBits(64), [
    for (var i = 0; i <= 64; i++) i.toRadixString(2).replaceAll('0', '').length,
  ], 64);

  // 53 detect squares vs brute enumeration of point triples.
  for (var t = 0; t < 100; t++) {
    final ds = n53.DetectSquares();
    final stored = <List<int>>[];
    for (var op = 0; op < 15; op++) {
      final p = [rng.nextInt(4), rng.nextInt(4)];
      if (rng.nextInt(3) > 0) {
        ds.add(p);
        stored.add(p);
      } else {
        var want = 0;
        for (var i = 0; i < stored.length; i++) {
          for (var j = 0; j < stored.length; j++) {
            for (var k = 0; k < stored.length; k++) {
              if (i == j || j == k || i == k) continue;
              final a = stored[i], b = stored[j], c = stored[k];
              // i is the diagonal corner, j shares p's x, k shares p's y (each triple counted once).
              final side = (a[0] - p[0]).abs();
              if (side == 0 || (a[1] - p[1]).abs() != side) continue;
              if (b[0] == p[0] && b[1] == a[1] && c[0] == a[0] && c[1] == p[1]) want++;
            }
          }
        }
        expectEq('53 squares', ds.count(p), want, (stored, p));
      }
    }
  }
}
