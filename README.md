# learnalgo

198 AlgoExpert-style interview problems solved in modern Dart (3.9+), one folder per problem. Each folder has:

- `<problem>.dart`: a runnable, self-checking solution (`dart run <file>` prints `ok:` lines and throws on any failed check).
- `README.md`: the problem in plain words, **how to build up the logic** from brute force to optimal, time and space complexity with justification, edge cases, and interview notes (follow-ups, LeetCode equivalents, common traps).

Built for FAANG-level interview preparation (Google, Microsoft, Meta, Amazon, Apple).

## Read this first: what this repo is and is not

- **The problem list is reconstructed, not scraped.** AlgoExpert's catalog is paywalled. The 198 problems here match the AlgoExpert question list as I know it (names, categories, difficulty tiers), but the exact count, tiering, and a few problem definitions on the live site may differ. Problems where I was unsure of the exact definition say so explicitly in their README (search for "Statement note" or "Clarification note").
- **Problem statements are paraphrased** in my own words. This repo is not affiliated with AlgoExpert. Use it alongside the real platform if you have access, and treat any disagreement as a prompt to re-read the official statement.
- **Every solution is executed.** `tool/run_all.sh` runs all 198 files; CI runs `dart format` (check), `dart analyze --fatal-infos` (strict casts, inference, raw types), and every solution on each push. `tool/stress_test.dart` additionally cross-checks about 60 of the trickier solutions against independent brute-force implementations on random inputs (it caught a real infinite-loop bug in Juice Bottling during development).

## Running

```bash
dart pub get                          # no dependencies; just creates package config
dart run medium/01_three_number_sum/three_number_sum.dart
tool/run_all.sh                       # run everything
tool/run_all.sh hard                  # run one difficulty (any path filter works)
dart run tool/stress_test.dart        # randomized brute-force cross-checks
dart analyze --fatal-infos
dart format .                         # 120-column page width, set in analysis_options.yaml
dart run tool/generate_index.dart     # rebuild the index below after adding problems
```

Each file is standalone (no shared imports), so you can copy any single file into DartPad.

## How to practice with this repo (the part that actually matters)

Reading solutions does not build interview skill. Use this loop per problem:

1. **Read only the Problem section** of the README. Close it.
2. **Set a timer**: 20 min (easy), 30 (medium), 45 (hard/very hard).
3. **Say the brute force out loud** with its complexity before anything else.
4. **Find the bottleneck** in the brute force ("what am I recomputing?", "what am I searching for repeatedly?"). That question leads to almost every optimization in this repo.
5. **Write the code in a blank file**, not in your IDE with autocomplete. Interviews use a plain editor or a whiteboard.
6. **Test by hand** on the smallest nontrivial input and one edge case, before running.
7. Only then read **Building up the logic** and compare. Note the exact step where your reasoning diverged. That step is what you study.
8. **Re-solve from scratch 3 days later and again 2 weeks later** (spaced repetition). A problem is "done" when you can solve it cold, explain complexity, and handle the listed follow-ups.

Track problems you failed; they are worth more than the ones you solved.

## Interview framework (use it every time)

1. **Clarify:** input size and ranges, duplicates, negatives, empty input, sorted or not, can I mutate the input, what to return when there is no answer.
2. **Examples:** walk one normal example and one edge case with the interviewer.
3. **Brute force:** state it with complexity. It proves understanding and gives a fallback.
4. **Optimize:** name the bottleneck, pick the data structure or pattern that removes it, state the new complexity **before** coding.
5. **Code:** clean names, helper functions, no premature micro-optimizations.
6. **Test:** trace your code on the example, then edge cases. Fix bugs by reasoning, not by guessing.
7. **Analyze:** final time and space, and what changes under follow-ups (streaming input, huge input, concurrency).

## 8-week study plan by pattern

Order matters: each week builds on the previous. Do easy -> medium -> hard within a week.

| Week | Theme | Problems |
|---|---|---|
| 1 | Arrays, hashing, two pointers | easy 01-06; medium 01-14; hard 01-08; very_hard 01-05 |
| 2 | Searching, sorting, greedy | easy 12-14, 19-23; medium 44-45, 57-58; hard 44-50; very_hard 31-34 |
| 3 | Strings, sliding window, tries | easy 24-30; medium 67-73; hard 53-58; very_hard 17, 35-37 |
| 4 | Linked lists, stacks | easy 15-16; medium 47-50, 59-66; hard 35-38, 51-52; very_hard 24-28 |
| 5 | Trees and BSTs | easy 07-10; medium 15-27; hard 09-14; very_hard 06-11 |
| 6 | Recursion and backtracking | easy 17-18; medium 51-56; hard 39-43; very_hard 29-30 |
| 7 | Graphs, heaps, famous algorithms | easy 11; medium 33-43, 46; hard 26-34; very_hard 18-23 |
| 8 | Dynamic programming | medium 28-32; hard 15-25; very_hard 12-16 |

Every problem appears exactly once. Treat very hard problems as stretch goals in the first pass; come back to them after week 8.

After week 8, do mixed random practice (pick problems by number with a random generator) to train **pattern recognition**, which is what interviews actually test.

## Pattern map: "when you see X, think Y"

| Signal in the problem | Pattern | Representative problems |
|---|---|---|
| Sorted array, pair/triplet with a target | Two pointers | medium 01 Three Number Sum, hard 01 Four Number Sum |
| "Does X exist?" asked repeatedly | Hash set / map | easy 01 Two Number Sum, hard 03 Largest Range |
| Contiguous subarray sum (with negatives) | Prefix sums + hash map | medium 11 Zero Sum Subarray, hard 06 Longest Subarray With Sum |
| Contiguous window with a constraint | Sliding window | hard 53 Longest Substring Without Duplication, very_hard 35 Smallest Substring Containing |
| Next/previous greater or smaller element | Monotonic stack | medium 64 Next Greater Element, hard 52 Largest Rectangle Under Skyline |
| Sorted input, O(log n) required | Binary search (incl. on a predicate or answer) | hard 44 Shifted Binary Search, very_hard 32 Optimal Assembly Line |
| Top k / k-th / streaming median | Heap | hard 34 Continuous Median, very_hard 23 Merge Sorted Arrays |
| Intervals | Sort by start + sweep | medium 09 Merge Overlapping Intervals, hard 32 Laptop Rentals |
| Tree: info needed from children | Bottom-up DFS returning a tuple | medium 22 Binary Tree Diameter, hard 13 Max Path Sum |
| Tree: info needed from ancestors | Top-down DFS with parameters | easy 08 Branch Sums, medium 16 Validate BST |
| Grid regions | Flood fill (DFS/BFS) | medium 38 River Sizes, hard 31 Largest Island |
| Shortest path, unweighted | BFS (multi-source if many starts) | medium 42 Minimum Passes Of Matrix |
| Shortest path, weighted | Dijkstra / A* / Bellman-Ford | hard 26, very_hard 18, very_hard 21 |
| Dependencies / ordering | Topological sort | hard 27 Topological Sort |
| Dynamic connectivity / grouping | Union-Find | medium 35 Union Find, hard 28 Kruskal's |
| All combinations / permutations | Backtracking | medium 51 Permutations, hard 41 Solve Sudoku |
| Optimal value over choices with overlapping subproblems | Dynamic programming | medium 29-31, hard 19 Knapsack, very_hard 12 |
| Many string prefix queries | Trie | hard 30 Boggle Board, hard 56-58 |
| Linked list middle / cycle / reorder | Fast-slow pointers + reversal | easy 16, hard 35, very_hard 26-27 |

## Complexity cheat sheet

**Input size -> what usually fits in time (about 10^8 simple operations per second):**

| n | Acceptable complexity |
|---|---|
| <= 12 | O(n!) |
| <= 20-25 | O(2^n) |
| <= 500 | O(n^3) |
| <= 5,000 | O(n^2) |
| <= 10^6 | O(n log n) |
| >= 10^7 | O(n) or O(log n) |

**Sorting algorithms:**

| Algorithm | Best | Average | Worst | Space | Stable | Folder |
|---|---|---|---|---|---|---|
| Bubble | O(n) | O(n^2) | O(n^2) | O(1) | Yes | easy/21 |
| Insertion | O(n) | O(n^2) | O(n^2) | O(1) | Yes | easy/22 |
| Selection | O(n^2) | O(n^2) | O(n^2) | O(1) | No | easy/23 |
| Merge | O(n log n) | O(n log n) | O(n log n) | O(n) | Yes | very_hard/33 |
| Quick | O(n log n) | O(n log n) | O(n^2) | O(log n) | No | hard/48 |
| Heap | O(n log n) | O(n log n) | O(n log n) | O(1) | No | hard/49 |
| Radix (LSD) | O(d(n + b)) | O(d(n + b)) | O(d(n + b)) | O(n + b) | Yes | hard/50 |

**Data structures:**

| Structure | Access | Search | Insert | Delete | Notes |
|---|---|---|---|---|---|
| Dynamic array | O(1) | O(n) | O(1) amortized at end, O(n) middle | O(n) | |
| Linked list | O(n) | O(n) | O(1) with node pointer | O(1) with node pointer | |
| Hash map / set | n/a | O(1) avg, O(n) worst | O(1) avg | O(1) avg | |
| Balanced BST | O(log n) | O(log n) | O(log n) | O(log n) | Ordered; Dart `SplayTreeMap` is amortized |
| Binary heap | O(1) min | O(n) | O(log n) | O(log n) root | Build is O(n) |
| Trie | n/a | O(L) | O(L) | O(L) | L = key length |
| Union-Find | n/a | O(alpha(n)) find | O(alpha(n)) union | n/a | With rank + path compression |

## Dart notes for interviews

- Dart 3 features used throughout: records `(int, int)` as tuples and map keys, patterns (`final [a, b] = pair;`, `if (x case final y?)`), `switch` expressions, `sync*` generators for lazy traversal, `.nonNulls`.
- `dart:core` has no priority queue. Files that need a heap include a small `_MinHeap` (see medium/46 Min Heap Construction for the full explanation); in real projects use `PriorityQueue` from `package:collection`.
- Use `Queue` from `dart:collection` for BFS. `List.removeAt(0)` is O(n).
- `~/` is integer division truncating toward zero. `%` always returns a non-negative result for a positive divisor (unlike Java/C++), which simplifies wrap-around arithmetic.
- `int` is 64-bit on native platforms and overflows silently (it becomes a JavaScript double on the web). Mention overflow when products or counts can grow large.
- Strings index UTF-16 code units. For ASCII inputs `codeUnitAt` is fastest; for real Unicode text use `runes` or `package:characters`.

## Problem index

<!-- INDEX:START -->

Total: 198 problems.

### Easy (30)

| # | Problem | Category | Pattern |
|---|---|---|---|
| 01 | [Two Number Sum](easy/01_two_number_sum/) | Arrays | Hash set / Two pointers |
| 02 | [Validate Subsequence](easy/02_validate_subsequence/) | Arrays | Two pointers (greedy matching) |
| 03 | [Sorted Squared Array](easy/03_sorted_squared_array/) | Arrays | Two pointers from both ends |
| 04 | [Tournament Winner](easy/04_tournament_winner/) | Arrays | Hash map counting |
| 05 | [Non-Constructible Change](easy/05_non_constructible_change/) | Arrays | Sorting + greedy invariant |
| 06 | [Transpose Matrix](easy/06_transpose_matrix/) | Arrays | Matrix index mapping |
| 07 | [Find Closest Value In BST](easy/07_find_closest_value_in_bst/) | Binary Search Trees | BST descent |
| 08 | [Branch Sums](easy/08_branch_sums/) | Binary Trees | DFS with accumulated state |
| 09 | [Node Depths](easy/09_node_depths/) | Binary Trees | DFS/BFS with depth |
| 10 | [Evaluate Expression Tree](easy/10_evaluate_expression_tree/) | Binary Trees | Postorder (bottom-up) recursion |
| 11 | [Depth-first Search](easy/11_depth_first_search/) | Graphs | DFS traversal |
| 12 | [Minimum Waiting Time](easy/12_minimum_waiting_time/) | Greedy | Sort then greedy (shortest job first) |
| 13 | [Class Photos](easy/13_class_photos/) | Greedy | Sort both, compare pairwise |
| 14 | [Tandem Bicycle](easy/14_tandem_bicycle/) | Greedy | Sort + pair opposite / same ends |
| 15 | [Remove Duplicates From Linked List](easy/15_remove_duplicates_from_linked_list/) | Linked Lists | Pointer skipping |
| 16 | [Middle Node](easy/16_middle_node/) | Linked Lists | Fast and slow pointers |
| 17 | [Nth Fibonacci](easy/17_nth_fibonacci/) | Recursion | Recursion -> memoization -> bottom-up DP |
| 18 | [Product Sum](easy/18_product_sum/) | Recursion | Recursion over nested structure |
| 19 | [Binary Search](easy/19_binary_search/) | Searching | Binary search |
| 20 | [Find Three Largest Numbers](easy/20_find_three_largest_numbers/) | Searching | Running top-k |
| 21 | [Bubble Sort](easy/21_bubble_sort/) | Sorting | Adjacent swaps |
| 22 | [Insertion Sort](easy/22_insertion_sort/) | Sorting | Sorted prefix + insertion |
| 23 | [Selection Sort](easy/23_selection_sort/) | Sorting | Repeated minimum selection |
| 24 | [Palindrome Check](easy/24_palindrome_check/) | Strings | Two pointers |
| 25 | [Caesar Cipher Encryptor](easy/25_caesar_cipher_encryptor/) | Strings | Modular arithmetic on character codes |
| 26 | [Run-Length Encoding](easy/26_run_length_encoding/) | Strings | Run tracking in one pass |
| 27 | [Common Characters](easy/27_common_characters/) | Strings | Set intersection |
| 28 | [Generate Document](easy/28_generate_document/) | Strings | Frequency counting |
| 29 | [First Non-Repeating Character](easy/29_first_non_repeating_character/) | Strings | Frequency map, two passes |
| 30 | [Semordnilap](easy/30_semordnilap/) | Strings | Hash set lookup |

### Medium (73)

| # | Problem | Category | Pattern |
|---|---|---|---|
| 01 | [Three Number Sum](medium/01_three_number_sum/) | Arrays | Sort + two pointers |
| 02 | [Smallest Difference](medium/02_smallest_difference/) | Arrays | Sort both + two pointers |
| 03 | [Move Element To End](medium/03_move_element_to_end/) | Arrays | Two pointers / partitioning |
| 04 | [Monotonic Array](medium/04_monotonic_array/) | Arrays | Single pass with two flags |
| 05 | [Spiral Traverse](medium/05_spiral_traverse/) | Arrays | Shrinking boundaries (matrix simulation) |
| 06 | [Longest Peak](medium/06_longest_peak/) | Arrays | Find anchors, expand outward |
| 07 | [Array Of Products](medium/07_array_of_products/) | Arrays | Prefix and suffix products |
| 08 | [First Duplicate Value](medium/08_first_duplicate_value/) | Arrays | Index-as-hash (sign marking) |
| 09 | [Merge Overlapping Intervals](medium/09_merge_overlapping_intervals/) | Arrays | Sort by start + sweep |
| 10 | [Best Seat](medium/10_best_seat/) | Arrays | Scan runs of free cells |
| 11 | [Zero Sum Subarray](medium/11_zero_sum_subarray/) | Arrays | Prefix sums + hash set |
| 12 | [Missing Numbers](medium/12_missing_numbers/) | Arrays | Math / XOR partitioning |
| 13 | [Majority Element](medium/13_majority_element/) | Arrays | Boyer-Moore majority vote |
| 14 | [Sweet And Savory](medium/14_sweet_and_savory/) | Arrays | Split + sort + two pointers |
| 15 | [BST Construction](medium/15_bst_construction/) | Binary Search Trees | BST insert / search / delete |
| 16 | [Validate BST](medium/16_validate_bst/) | Binary Search Trees | Top-down bounds |
| 17 | [BST Traversal](medium/17_bst_traversal/) | Binary Search Trees | DFS orders |
| 18 | [Min Height BST](medium/18_min_height_bst/) | Binary Search Trees | Divide and conquer |
| 19 | [Find Kth Largest Value In BST](medium/19_find_kth_largest_value_in_bst/) | Binary Search Trees | Reverse in-order with early exit |
| 20 | [Reconstruct BST](medium/20_reconstruct_bst/) | Binary Search Trees | Pre-order consumption with bounds |
| 21 | [Invert Binary Tree](medium/21_invert_binary_tree/) | Binary Trees | Visit every node and swap children |
| 22 | [Binary Tree Diameter](medium/22_binary_tree_diameter/) | Binary Trees | Bottom-up DFS returning multiple values |
| 23 | [Find Successor](medium/23_find_successor/) | Binary Trees | Structural case analysis with parent pointers |
| 24 | [Height Balanced Binary Tree](medium/24_height_balanced_binary_tree/) | Binary Trees | Bottom-up DFS with sentinel |
| 25 | [Merge Binary Trees](medium/25_merge_binary_trees/) | Binary Trees | Simultaneous traversal of two trees |
| 26 | [Symmetrical Tree](medium/26_symmetrical_tree/) | Binary Trees | Paired traversal (mirror comparison) |
| 27 | [Split Binary Tree](medium/27_split_binary_tree/) | Binary Trees | Subtree sums (post-order) |
| 28 | [Max Subset Sum No Adjacent](medium/28_max_subset_sum_no_adjacent/) | Dynamic Programming | Linear DP (take / skip) |
| 29 | [Number Of Ways To Make Change](medium/29_number_of_ways_to_make_change/) | Dynamic Programming | Unbounded knapsack (counting) |
| 30 | [Min Number Of Coins For Change](medium/30_min_number_of_coins_for_change/) | Dynamic Programming | Unbounded knapsack (minimization) |
| 31 | [Levenshtein Distance](medium/31_levenshtein_distance/) | Dynamic Programming | 2D string DP (edit distance) |
| 32 | [Number Of Ways To Traverse Graph](medium/32_number_of_ways_to_traverse_graph/) | Dynamic Programming | Grid DP / combinatorics |
| 33 | [Kadane's Algorithm](medium/33_kadanes_algorithm/) | Famous Algorithms | DP on "ending at i" |
| 34 | [Stable Internships](medium/34_stable_internships/) | Famous Algorithms | Gale-Shapley stable matching |
| 35 | [Union Find](medium/35_union_find/) | Famous Algorithms | Disjoint Set Union (DSU) |
| 36 | [Single Cycle Check](medium/36_single_cycle_check/) | Graphs | Functional graph traversal, counting |
| 37 | [Breadth-first Search](medium/37_breadth_first_search/) | Graphs | BFS with a queue |
| 38 | [River Sizes](medium/38_river_sizes/) | Graphs | Connected components on a grid (DFS/BFS flood fill) |
| 39 | [Youngest Common Ancestor](medium/39_youngest_common_ancestor/) | Graphs | Lowest common ancestor with parent pointers |
| 40 | [Remove Islands](medium/40_remove_islands/) | Graphs | Flood fill from the boundary (reverse thinking) |
| 41 | [Cycle In Graph](medium/41_cycle_in_graph/) | Graphs | DFS three-color (back edge detection) |
| 42 | [Minimum Passes Of Matrix](medium/42_minimum_passes_of_matrix/) | Graphs | Multi-source BFS (levels = time) |
| 43 | [Two-Colorable](medium/43_two_colorable/) | Graphs | Bipartite check via BFS/DFS coloring |
| 44 | [Task Assignment](medium/44_task_assignment/) | Greedy | Sort + pair smallest with largest |
| 45 | [Valid Starting City](medium/45_valid_starting_city/) | Greedy | Circular prefix sums (gas station) |
| 46 | [Min Heap Construction](medium/46_min_heap_construction/) | Heaps | Array-backed binary heap |
| 47 | [Linked List Construction](medium/47_linked_list_construction/) | Linked Lists | Doubly linked list pointer surgery |
| 48 | [Remove Kth Node From End](medium/48_remove_kth_node_from_end/) | Linked Lists | Two pointers with a fixed gap |
| 49 | [Sum of Linked Lists](medium/49_sum_of_linked_lists/) | Linked Lists | Digit-by-digit addition with carry |
| 50 | [Merging Linked Lists](medium/50_merging_linked_lists/) | Linked Lists | Two pointers that equalize path lengths |
| 51 | [Permutations](medium/51_permutations/) | Recursion | Backtracking |
| 52 | [Powerset](medium/52_powerset/) | Recursion | Subset generation (iterative doubling / bitmask / backtracking) |
| 53 | [Phone Number Mnemonics](medium/53_phone_number_mnemonics/) | Recursion | Backtracking over a fixed-length slot array |
| 54 | [Staircase Traversal](medium/54_staircase_traversal/) | Recursion | DP with a sliding window sum |
| 55 | [Blackjack Probability](medium/55_blackjack_probability/) | Recursion | Probability DP with memoization |
| 56 | [Reveal Minesweeper](medium/56_reveal_minesweeper/) | Recursion | Flood fill with a stopping condition |
| 57 | [Search In Sorted Matrix](medium/57_search_in_sorted_matrix/) | Searching | Staircase search from a corner |
| 58 | [Three Number Sort](medium/58_three_number_sort/) | Sorting | Dutch national flag (3-way partition) |
| 59 | [Min Max Stack Construction](medium/59_min_max_stack_construction/) | Stacks | Augmenting each stack entry with aggregate state |
| 60 | [Balanced Brackets](medium/60_balanced_brackets/) | Stacks | Stack matching |
| 61 | [Sunset Views](medium/61_sunset_views/) | Stacks | Running maximum from one side (or monotonic stack) |
| 62 | [Best Digits](medium/62_best_digits/) | Stacks | Monotonic stack (greedy digit removal) |
| 63 | [Sort Stack](medium/63_sort_stack/) | Stacks | Recursion as an implicit second stack |
| 64 | [Next Greater Element](medium/64_next_greater_element/) | Stacks | Monotonic stack (circular) |
| 65 | [Reverse Polish Notation](medium/65_reverse_polish_notation/) | Stacks | Stack-based expression evaluation |
| 66 | [Colliding Asteroids](medium/66_colliding_asteroids/) | Stacks | Stack simulation |
| 67 | [Longest Palindromic Substring](medium/67_longest_palindromic_substring/) | Strings | Expand around center |
| 68 | [Group Anagrams](medium/68_group_anagrams/) | Strings | Canonical key + hash map grouping |
| 69 | [Valid IP Addresses](medium/69_valid_ip_addresses/) | Strings | Bounded enumeration / backtracking with pruning |
| 70 | [Reverse Words In String](medium/70_reverse_words_in_string/) | Strings | Tokenize and reverse (or reverse twice) |
| 71 | [Minimum Characters For Words](medium/71_minimum_characters_for_words/) | Strings | Per-key maximum of frequency maps |
| 72 | [One Edit](medium/72_one_edit/) | Strings | Two pointers with a single allowed mismatch |
| 73 | [Suffix Trie Construction](medium/73_suffix_trie_construction/) | Tries | Trie insertion of every suffix |

### Hard (58)

| # | Problem | Category | Pattern |
|---|---|---|---|
| 01 | [Four Number Sum](hard/01_four_number_sum/) | Arrays | Pair sums in a hash map (meet in the middle) |
| 02 | [Subarray Sort](hard/02_subarray_sort/) | Arrays | Find extremes of the unsorted region |
| 03 | [Largest Range](hard/03_largest_range/) | Arrays | Hash set, expand only from run starts |
| 04 | [Min Rewards](hard/04_min_rewards/) | Arrays | Two-pass greedy (left and right constraints) |
| 05 | [Zigzag Traverse](hard/05_zigzag_traverse/) | Arrays | Anti-diagonal indexing |
| 06 | [Longest Subarray With Sum](hard/06_longest_subarray_with_sum/) | Arrays | Sliding window (non-negative) / prefix-sum map (general) |
| 07 | [Knight Connection](hard/07_knight_connection/) | Arrays | BFS on an implicit infinite graph + a halving argument |
| 08 | [Count Squares](hard/08_count_squares/) | Arrays | Geometry + hash set of points (fix a diagonal) |
| 09 | [Same BSTs](hard/09_same_bsts/) | Binary Search Trees | Recursive structure comparison without building trees |
| 10 | [Validate Three Nodes](hard/10_validate_three_nodes/) | Binary Search Trees | BST search between nodes |
| 11 | [Repair BST](hard/11_repair_bst/) | Binary Search Trees | In-order traversal to find inversions |
| 12 | [Sum BSTs](hard/12_sum_bsts/) | Binary Search Trees | Bottom-up DFS returning subtree summaries |
| 13 | [Max Path Sum In Binary Tree](hard/13_max_path_sum_in_binary_tree/) | Binary Trees | Bottom-up DFS with "branch" vs "bent path" |
| 14 | [Find Nodes Distance K](hard/14_find_nodes_distance_k/) | Binary Trees | Tree -> undirected graph, then BFS |
| 15 | [Max Sum Increasing Subsequence](hard/15_max_sum_increasing_subsequence/) | Dynamic Programming | LIS-style DP (ending at i) with reconstruction |
| 16 | [Longest Common Subsequence](hard/16_longest_common_subsequence/) | Dynamic Programming | 2D string DP with backtracking |
| 17 | [Min Number Of Jumps](hard/17_min_number_of_jumps/) | Dynamic Programming | DP O(n^2) -> greedy level expansion O(n) |
| 18 | [Water Area](hard/18_water_area/) | Dynamic Programming | Prefix/suffix maxima -> two pointers |
| 19 | [Knapsack Problem](hard/19_knapsack_problem/) | Dynamic Programming | 0/1 knapsack |
| 20 | [Disk Stacking](hard/20_disk_stacking/) | Dynamic Programming | Sort + LIS-style DP over a partial order |
| 21 | [Numbers In Pi](hard/21_numbers_in_pi/) | Dynamic Programming | Word break (min pieces) |
| 22 | [Maximum Sum Submatrix](hard/22_maximum_sum_submatrix/) | Dynamic Programming | 2D prefix sums |
| 23 | [Maximize Expression](hard/23_maximize_expression/) | Dynamic Programming | Chained running maxima |
| 24 | [Dice Throws](hard/24_dice_throws/) | Dynamic Programming | Counting DP over (items, total) |
| 25 | [Juice Bottling](hard/25_juice_bottling/) | Dynamic Programming | Rod cutting (unbounded knapsack on size) |
| 26 | [Dijkstra's Algorithm](hard/26_dijkstras_algorithm/) | Famous Algorithms | Greedy shortest paths with a priority queue |
| 27 | [Topological Sort](hard/27_topological_sort/) | Famous Algorithms | Kahn's algorithm (in-degree BFS) or DFS post-order |
| 28 | [Kruskal's Algorithm](hard/28_kruskals_algorithm/) | Famous Algorithms | Sort edges + Union-Find (MST) |
| 29 | [Prim's Algorithm](hard/29_prims_algorithm/) | Famous Algorithms | Grow a tree with a min-heap of crossing edges (MST) |
| 30 | [Boggle Board](hard/30_boggle_board/) | Graphs | Trie + backtracking DFS on a grid |
| 31 | [Largest Island](hard/31_largest_island/) | Graphs | Label connected components, then evaluate each candidate cell |
| 32 | [Laptop Rentals](hard/32_laptop_rentals/) | Heaps | Interval overlap: min-heap of end times or sweep line |
| 33 | [Sort K-Sorted Array](hard/33_sort_k_sorted_array/) | Heaps | Sliding window min-heap |
| 34 | [Continuous Median](hard/34_continuous_median/) | Heaps | Two heaps (lower max-heap, upper min-heap) |
| 35 | [Find Loop](hard/35_find_loop/) | Linked Lists | Floyd's cycle detection |
| 36 | [Reverse Linked List](hard/36_reverse_linked_list/) | Linked Lists | Pointer reversal |
| 37 | [Merge Linked Lists](hard/37_merge_linked_lists/) | Linked Lists | Merge step with a dummy head |
| 38 | [Shift Linked List](hard/38_shift_linked_list/) | Linked Lists | Length + modular offset + relink |
| 39 | [Lowest Common Manager](hard/39_lowest_common_manager/) | Recursion | Post-order counting (LCA without parent pointers) |
| 40 | [Interweaving Strings](hard/40_interweaving_strings/) | Recursion | 2D DP over two string prefixes |
| 41 | [Solve Sudoku](hard/41_solve_sudoku/) | Recursion | Constraint backtracking |
| 42 | [Generate Div Tags](hard/42_generate_div_tags/) | Recursion | Backtracking with validity counters (balanced parentheses) |
| 43 | [Ambiguous Measurements](hard/43_ambiguous_measurements/) | Recursion | Memoized recursion over a range state |
| 44 | [Shifted Binary Search](hard/44_shifted_binary_search/) | Searching | Binary search on a rotated array |
| 45 | [Search For Range](hard/45_search_for_range/) | Searching | Lower bound / upper bound binary search |
| 46 | [Quickselect](hard/46_quickselect/) | Searching | Partition-based selection |
| 47 | [Index Equals Value](hard/47_index_equals_value/) | Searching | Binary search on a derived monotonic function |
| 48 | [Quick Sort](hard/48_quick_sort/) | Sorting | Divide and conquer via partitioning |
| 49 | [Heap Sort](hard/49_heap_sort/) | Sorting | Max-heap + repeated extraction |
| 50 | [Radix Sort](hard/50_radix_sort/) | Sorting | Non-comparison sort (digit by digit with counting sort) |
| 51 | [Shorten Path](hard/51_shorten_path/) | Stacks | Stack of path segments |
| 52 | [Largest Rectangle Under Skyline](hard/52_largest_rectangle_under_skyline/) | Stacks | Monotonic stack (previous/next smaller element) |
| 53 | [Longest Substring Without Duplication](hard/53_longest_substring_without_duplication/) | Strings | Sliding window with last-seen positions |
| 54 | [Underscorify Substring](hard/54_underscorify_substring/) | Strings | Find match intervals, merge, rebuild |
| 55 | [Pattern Matcher](hard/55_pattern_matcher/) | Strings | Enumerate one length, derive the other |
| 56 | [Multi String Search](hard/56_multi_string_search/) | Tries | Trie of patterns, scanned from every text position |
| 57 | [Longest Most Frequent Prefix](hard/57_longest_most_frequent_prefix/) | Tries | Trie with prefix counts |
| 58 | [Shortest Unique Prefixes](hard/58_shortest_unique_prefixes/) | Tries | Trie with prefix counts |

### Very Hard (37)

| # | Problem | Category | Pattern |
|---|---|---|---|
| 01 | [Apartment Hunting](very_hard/01_apartment_hunting/) | Arrays | Nearest-occurrence precomputation (two sweeps) |
| 02 | [Calendar Matching](very_hard/02_calendar_matching/) | Arrays | Interval merge + gap finding |
| 03 | [Waterfall Streams](very_hard/03_waterfall_streams/) | Arrays | Row-by-row simulation with fractional flow |
| 04 | [Minimum Area Rectangle](very_hard/04_minimum_area_rectangle/) | Arrays | Diagonal pairs + hash set of points |
| 05 | [Line Through Points](very_hard/05_line_through_points/) | Arrays | Anchor point + hash map of exact slopes |
| 06 | [Right Smaller Than](very_hard/06_right_smaller_than/) | Binary Search Trees | Augmented BST or merge sort counting |
| 07 | [Iterative In-order Traversal](very_hard/07_iterative_in_order_traversal/) | Binary Trees | Stackless traversal using parent pointers |
| 08 | [Flatten Binary Tree](very_hard/08_flatten_binary_tree/) | Binary Trees | Bottom-up recursion returning list endpoints |
| 09 | [Right Sibling Tree](very_hard/09_right_sibling_tree/) | Binary Trees | In-place pointer rewiring with careful ordering |
| 10 | [All Kinds Of Node Depths](very_hard/10_all_kinds_of_node_depths/) | Binary Trees | Bottom-up aggregation with subtree sizes |
| 11 | [Compare Leaf Traversal](very_hard/11_compare_leaf_traversal/) | Binary Trees | Lockstep lazy traversal (generators / explicit stacks) |
| 12 | [Max Profit With K Transactions](very_hard/12_max_profit_with_k_transactions/) | Dynamic Programming | 2D DP with a running-max optimization |
| 13 | [Palindrome Partitioning Min Cuts](very_hard/13_palindrome_partitioning_min_cuts/) | Dynamic Programming | Palindrome table + prefix DP |
| 14 | [Longest Increasing Subsequence](very_hard/14_longest_increasing_subsequence/) | Dynamic Programming | Patience sorting (binary search over tails) |
| 15 | [Longest String Chain](very_hard/15_longest_string_chain/) | Dynamic Programming | DP on a DAG ordered by length |
| 16 | [Square Of Zeroes](very_hard/16_square_of_zeroes/) | Dynamic Programming | Precomputed run lengths for O(1) border checks |
| 17 | [Knuth-Morris-Pratt Algorithm](very_hard/17_knuth_morris_pratt/) | Famous Algorithms | Failure function (longest prefix-suffix) string matching |
| 18 | [A* Algorithm](very_hard/18_a_star_algorithm/) | Famous Algorithms | Best-first search with an admissible heuristic |
| 19 | [Rectangle Mania](very_hard/19_rectangle_mania/) | Graphs | Canonical diagonal + point hash set |
| 20 | [Airport Connections](very_hard/20_airport_connections/) | Graphs | Strongly connected components + condensation DAG |
| 21 | [Detect Arbitrage](very_hard/21_detect_arbitrage/) | Graphs | Log transform + Bellman-Ford negative cycle detection |
| 22 | [Two-Edge-Connected Graph](very_hard/22_two_edge_connected_graph/) | Graphs | Tarjan's bridge finding (DFS low-link) |
| 23 | [Merge Sorted Arrays](very_hard/23_merge_sorted_arrays/) | Heaps | K-way merge with a min-heap |
| 24 | [LRU Cache](very_hard/24_lru_cache/) | Linked Lists | Hash map + doubly linked list |
| 25 | [Rearrange Linked List](very_hard/25_rearrange_linked_list/) | Linked Lists | Stable partition into sublists with dummy heads |
| 26 | [Linked List Palindrome](very_hard/26_linked_list_palindrome/) | Linked Lists | Middle + reverse second half |
| 27 | [Zip Linked List](very_hard/27_zip_linked_list/) | Linked Lists | Split + reverse + interleave |
| 28 | [Node Swap](very_hard/28_node_swap/) | Linked Lists | Pairwise relinking with a dummy head |
| 29 | [Number Of Binary Tree Topologies](very_hard/29_number_of_binary_tree_topologies/) | Recursion | Catalan recurrence (DP over split points) |
| 30 | [Non-Attacking Queens](very_hard/30_non_attacking_queens/) | Recursion | Backtracking with O(1) conflict checks (bitmasks) |
| 31 | [Median Of Two Sorted Arrays](very_hard/31_median_of_two_sorted_arrays/) | Searching | Binary search on a partition |
| 32 | [Optimal Assembly Line](very_hard/32_optimal_assembly_line/) | Searching | Binary search on the answer + greedy check |
| 33 | [Merge Sort](very_hard/33_merge_sort/) | Sorting | Divide and conquer |
| 34 | [Count Inversions](very_hard/34_count_inversions/) | Sorting | Merge sort with counting |
| 35 | [Smallest Substring Containing](very_hard/35_smallest_substring_containing/) | Strings | Variable-size sliding window with counts |
| 36 | [Longest Balanced Substring](very_hard/36_longest_balanced_substring/) | Strings | Stack of indices, or two counter scans |
| 37 | [Strings Made Up Of Strings](very_hard/37_strings_made_up_of_strings/) | Strings | Word break (DP) accelerated with a trie |

<!-- INDEX:END -->
