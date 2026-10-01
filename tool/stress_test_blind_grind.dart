// Randomized cross-checks for the blind75_grind75/ set against independent, deliberately naive
// brute forces. Run: dart run tool/stress_test_blind_grind.dart

import 'dart:io';
import 'dart:math';
import '../blind75_grind75/01_flood_fill/flood_fill.dart' as g01;
import '../blind75_grind75/02_implement_queue_using_stacks/implement_queue_using_stacks.dart' as g02;
import '../blind75_grind75/03_first_bad_version/first_bad_version.dart' as g03;
import '../blind75_grind75/04_longest_palindrome/longest_palindrome.dart' as g04;
import '../blind75_grind75/05_add_binary/add_binary.dart' as g05;
import '../blind75_grind75/06_zero_one_matrix/zero_one_matrix.dart' as g06;
import '../blind75_grind75/07_lowest_common_ancestor_of_binary_tree/lowest_common_ancestor_of_binary_tree.dart' as g07;
import '../blind75_grind75/08_string_to_integer_atoi/string_to_integer_atoi.dart' as g08;
import '../blind75_grind75/09_find_all_anagrams_in_a_string/find_all_anagrams_in_a_string.dart' as g09;
import '../blind75_grind75/10_minimum_height_trees/minimum_height_trees.dart' as g10;
import '../blind75_grind75/11_basic_calculator/basic_calculator.dart' as g11;
import '../blind75_grind75/12_maximum_profit_in_job_scheduling/maximum_profit_in_job_scheduling.dart' as g12;
import '../blind75_grind75/13_combination_sum_iv/combination_sum_iv.dart' as g13;

final rng = Random(31);
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

void main() {
  for (var t = 0; t < 300; t++) {
    // 01 flood fill vs BFS.
    final r = 1 + rng.nextInt(4), c = 1 + rng.nextInt(4);
    final img = [for (var i = 0; i < r; i++) randList(c, c, 0, 2)];
    final sr = rng.nextInt(r), sc = rng.nextInt(c), color = rng.nextInt(3);
    final want = [
      for (final row in img) [...row],
    ];
    final orig = img[sr][sc];
    final seen = {(sr, sc)};
    final queue = [(sr, sc)];
    for (var q = 0; q < queue.length; q++) {
      final (x, y) = queue[q];
      want[x][y] = color;
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < r && ny < c && img[nx][ny] == orig && seen.add((nx, ny))) queue.add((nx, ny));
      }
    }
    expectEq(
      '01 flood',
      g01.floodFill(
        [
          for (final row in img) [...row],
        ],
        sr,
        sc,
        color,
      ),
      want,
      (img, sr, sc, color),
    );

    // 03 first bad version: every n and boundary.
    final n = 1 + rng.nextInt(50), firstBad = 1 + rng.nextInt(n);
    expectEq('03 bad', g03.firstBadVersion(n, (v) => v >= firstBad), firstBad, (n, firstBad));

    // 04 longest palindrome: the largest letter subset (by position) that can be permuted into a palindrome.
    final s4 = randWord(1, 9, 'aAb');
    var best4 = 0;
    for (var mask = 1; mask < 1 << s4.length; mask++) {
      final counts = <String, int>{};
      for (var i = 0; i < s4.length; i++) {
        if (mask & (1 << i) != 0) counts[s4[i]] = (counts[s4[i]] ?? 0) + 1;
      }
      if (counts.values.where((v) => v.isOdd).length <= 1) {
        best4 = max(best4, counts.values.fold(0, (a, b) => a + b));
      }
    }
    expectEq('04 palindrome', g04.longestPalindrome(s4), best4, s4);

    // 05 add binary vs BigInt.
    final a5 = '1${randWord(0, 40, '01')}', b5 = rng.nextBool() ? '0' : '1${randWord(0, 40, '01')}';
    expectEq(
      '05 binary',
      g05.addBinary(a5, b5),
      (BigInt.parse(a5, radix: 2) + BigInt.parse(b5, radix: 2)).toRadixString(2),
      (a5, b5),
    );

    // 06 01 matrix vs BFS from every cell (grids with at least one zero).
    final m6 = [for (var i = 0; i < r; i++) randList(c, c, 0, 1)];
    m6[rng.nextInt(r)][rng.nextInt(c)] = 0;
    final want6 = [
      for (var i = 0; i < r; i++)
        [
          for (var j = 0; j < c; j++)
            () {
              var best = 1 << 30;
              for (var x = 0; x < r; x++) {
                for (var y = 0; y < c; y++) {
                  if (m6[x][y] == 0) best = min(best, (x - i).abs() + (y - j).abs()); // no walls: Manhattan
                }
              }
              return best;
            }(),
        ],
    ];
    expectEq('06 bfs', g06.updateMatrix(m6), want6, m6);
    expectEq('06 dp', g06.updateMatrixDp(m6), want6, m6);

    // 08 atoi vs a regex reference with BigInt clamping.
    final s8 = randWord(0, 14, '  +-0123456789a');
    final match = RegExp(r'^ *([+-]?)(\d+)').firstMatch(s8);
    var want8 = 0;
    if (match != null) {
      var v = BigInt.parse(match.group(2)!);
      if (match.group(1) == '-') v = -v;
      final hi = BigInt.from(2147483647), lo = BigInt.from(-2147483648);
      want8 = (v > hi ? hi : (v < lo ? lo : v)).toInt();
    }
    expectEq('08 atoi', g08.myAtoi(s8), want8, s8);

    // 09 anagrams vs sorting every window.
    final s9 = randWord(0, 10, 'abc'), p9 = randWord(1, 3, 'abc');
    final key = (p9.split('')..sort()).join();
    expectEq(
      '09 anagrams',
      g09.findAnagrams(s9, p9),
      [
        for (var i = 0; i + p9.length <= s9.length; i++)
          if ((s9.substring(i, i + p9.length).split('')..sort()).join() == key) i,
      ],
      (s9, p9),
    );

    // 12 job scheduling vs every subset.
    final jobs = [
      for (var i = 0; i < 1 + rng.nextInt(8); i++) [rng.nextInt(10), 0, 1 + rng.nextInt(20)],
    ];
    for (final j in jobs) {
      j[1] = j[0] + 1 + rng.nextInt(4);
    }
    var best12 = 0;
    for (var mask = 0; mask < 1 << jobs.length; mask++) {
      final pick = [
        for (var i = 0; i < jobs.length; i++)
          if (mask & (1 << i) != 0) jobs[i],
      ]..sort((x, y) => x[0].compareTo(y[0]));
      var ok = true;
      for (var i = 1; i < pick.length; i++) {
        if (pick[i][0] < pick[i - 1][1]) ok = false;
      }
      if (ok) best12 = max(best12, pick.fold(0, (s, j) => s + j[2]));
    }
    expectEq(
      '12 jobs',
      g12.jobScheduling([for (final j in jobs) j[0]], [for (final j in jobs) j[1]], [for (final j in jobs) j[2]]),
      best12,
      jobs,
    );

    // 13 combination sum IV vs plain recursion.
    final nums = {for (var i = 0; i < 1 + rng.nextInt(3); i++) 1 + rng.nextInt(5)}.toList();
    final target = rng.nextInt(12);
    int ways(int rem) => rem == 0 ? 1 : nums.where((x) => x <= rem).fold(0, (s, x) => s + ways(rem - x));
    expectEq('13 combo IV', g13.combinationSum4(nums, target), ways(target), (nums, target));
  }

  // 02 queue vs a list used as a queue.
  for (var t = 0; t < 100; t++) {
    final q = g02.MyQueue();
    final model = <int>[];
    for (var op = 0; op < 30; op++) {
      if (model.isEmpty || rng.nextBool()) {
        final v = rng.nextInt(100);
        q.push(v);
        model.add(v);
      } else if (rng.nextBool()) {
        expectEq('02 pop', q.pop(), model.removeAt(0), op);
      } else {
        expectEq('02 peek', q.peek(), model.first, op);
      }
      expectEq('02 empty', q.empty(), model.isEmpty, op);
    }
  }

  // 07 LCA vs ancestor sets on random trees.
  for (var t = 0; t < 200; t++) {
    final size = 1 + rng.nextInt(10);
    final nodes = [for (var i = 0; i < size; i++) g07.TreeNode(i)];
    final parent = <int, int>{};
    for (var i = 1; i < size; i++) {
      while (true) {
        final p = rng.nextInt(i);
        if (rng.nextBool() && nodes[p].left == null) {
          nodes[p].left = nodes[i];
        } else if (nodes[p].right == null) {
          nodes[p].right = nodes[i];
        } else {
          continue;
        }
        parent[i] = p;
        break;
      }
    }
    final a = rng.nextInt(size), b = rng.nextInt(size);
    List<int> chain(int x) => [x, if (parent.containsKey(x)) ...chain(parent[x]!)];
    final ancestorsOfA = chain(a).toSet();
    final want = chain(b).firstWhere(ancestorsOfA.contains);
    expectEq('07 lca', g07.lowestCommonAncestor(nodes[0], nodes[a], nodes[b])!.value, want, (size, a, b));
  }

  // 10 minimum height trees vs BFS height from every node.
  for (var t = 0; t < 200; t++) {
    final n = 1 + rng.nextInt(9);
    final edges = [
      for (var v = 1; v < n; v++) [rng.nextInt(v), v],
    ];
    final adj = List.generate(n, (_) => <int>[]);
    for (final e in edges) {
      adj[e[0]].add(e[1]);
      adj[e[1]].add(e[0]);
    }
    int height(int root) {
      final depth = {root: 0};
      final queue = [root];
      for (var q = 0; q < queue.length; q++) {
        for (final w in adj[queue[q]]) {
          if (!depth.containsKey(w)) {
            depth[w] = depth[queue[q]]! + 1;
            queue.add(w);
          }
        }
      }
      return depth.values.reduce(max);
    }

    final heights = [for (var v = 0; v < n; v++) height(v)];
    final best = heights.reduce(min);
    expectEq('10 mht', g10.findMinHeightTrees(n, edges), [
      for (var v = 0; v < n; v++)
        if (heights[v] == best) v,
    ], edges);
  }

  // 11 calculator vs a recursive-descent evaluator over random expressions.
  for (var t = 0; t < 300; t++) {
    String expr(int depth) {
      final parts = <String>[];
      final terms = 1 + rng.nextInt(3);
      for (var i = 0; i < terms; i++) {
        final op = i == 0 ? (rng.nextInt(4) == 0 ? '-' : '') : (rng.nextBool() ? ' + ' : ' - ');
        final term = depth < 3 && rng.nextInt(3) == 0 ? '(${expr(depth + 1)})' : '${rng.nextInt(100)}';
        parts.add('$op$term');
      }
      return parts.join();
    }

    final e = expr(0);
    final tokens = RegExp(r'\d+|[()+\-]').allMatches(e).map((m) => m[0]!).toList();
    var pos = 0;
    late int Function() parseExpr;
    int parseTerm() {
      final tok = tokens[pos++];
      if (tok == '(') {
        final v = parseExpr();
        pos++; // ')'
        return v;
      }
      if (tok == '-') return -parseTerm();
      return int.parse(tok);
    }

    parseExpr = () {
      var v = parseTerm();
      while (pos < tokens.length && (tokens[pos] == '+' || tokens[pos] == '-')) {
        final op = tokens[pos++];
        final rhs = parseTerm();
        v = op == '+' ? v + rhs : v - rhs;
      }
      return v;
    };
    expectEq('11 calc', g11.calculate(e), parseExpr(), e);
  }

  print(failures == 0 ? 'ALL BLIND/GRIND STRESS TESTS PASSED' : 'failures: $failures');
  if (failures > 0) exitCode = 1;
}
