# NeetCode 150 in this repo

Every problem on the NeetCode 150 list is solved somewhere in this repository. The 60 folders in `neetcode/` are the ones that were **not already covered** by the AlgoExpert set (`easy/`, `medium/`, `hard/`, `very_hard/`) or by `more_problems/`. The table below maps all 150 problems, in NeetCode's category order, to the folder that solves them.

| Where the 150 live | Count |
|---|---|
| `neetcode/` (this folder) | 60 |
| `medium/` | 32 |
| `more_problems/` | 28 |
| `hard/` | 21 |
| `very_hard/` | 6 |
| `easy/` | 3 |

**How to use it:** work through NeetCode's categories in order (the roadmap builds each topic on the previous one). For each problem, open the linked folder; every folder has a runnable, tested Dart solution and a README in the same chapter format (problem, hand example, brute force, optimization, code walkthrough, dry run, complexity, edge cases, mistakes, follow-ups).

**Notes on accuracy:**

- The list is the NeetCode 150 as I know it (the version grouped into 18 categories). NeetCode occasionally revises its lists; if a problem on the live site is missing here, it is likely one of those revisions.
- Rows with a note point to an AlgoExpert-style problem that is the **same algorithm with a different interface** (for example, River Sizes returns every island size, and Number of Islands is the count of that list). The note says what differs. The LeetCode statement is the one to practice against for exact input and output formats.

## The map

### Arrays & Hashing (9)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Contains Duplicate | 217 | [neetcode/01_contains_duplicate](../neetcode/01_contains_duplicate/) |  |
| Valid Anagram | 242 | [neetcode/02_valid_anagram](../neetcode/02_valid_anagram/) |  |
| Two Sum | 1 | [easy/01_two_number_sum](../easy/01_two_number_sum/) | returns the values; the indices version is a follow-up in the README |
| Group Anagrams | 49 | [medium/68_group_anagrams](../medium/68_group_anagrams/) |  |
| Top K Frequent Elements | 347 | [more_problems/09_top_k_frequent_elements](../more_problems/09_top_k_frequent_elements/) |  |
| Encode and Decode Strings | 271 | [neetcode/03_encode_and_decode_strings](../neetcode/03_encode_and_decode_strings/) |  |
| Product of Array Except Self | 238 | [medium/07_array_of_products](../medium/07_array_of_products/) | Array Of Products |
| Valid Sudoku | 36 | [neetcode/04_valid_sudoku](../neetcode/04_valid_sudoku/) |  |
| Longest Consecutive Sequence | 128 | [hard/03_largest_range](../hard/03_largest_range/) | Largest Range returns the range; its length is the answer |

### Two Pointers (5)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Valid Palindrome | 125 | [neetcode/05_valid_palindrome](../neetcode/05_valid_palindrome/) |  |
| Two Sum II - Input Array Is Sorted | 167 | [easy/01_two_number_sum](../easy/01_two_number_sum/) | the two-pointer variant in the same file |
| 3Sum | 15 | [medium/01_three_number_sum](../medium/01_three_number_sum/) | Three Number Sum |
| Container With Most Water | 11 | [more_problems/10_container_with_most_water](../more_problems/10_container_with_most_water/) |  |
| Trapping Rain Water | 42 | [hard/18_water_area](../hard/18_water_area/) | Water Area |

### Sliding Window (6)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Best Time to Buy and Sell Stock | 121 | [more_problems/01_best_time_to_buy_and_sell_stock](../more_problems/01_best_time_to_buy_and_sell_stock/) |  |
| Longest Substring Without Repeating Characters | 3 | [hard/53_longest_substring_without_duplication](../hard/53_longest_substring_without_duplication/) |  |
| Longest Repeating Character Replacement | 424 | [more_problems/16_longest_repeating_character_replacement](../more_problems/16_longest_repeating_character_replacement/) |  |
| Permutation in String | 567 | [neetcode/06_permutation_in_string](../neetcode/06_permutation_in_string/) |  |
| Minimum Window Substring | 76 | [very_hard/35_smallest_substring_containing](../very_hard/35_smallest_substring_containing/) | Smallest Substring Containing |
| Sliding Window Maximum | 239 | [more_problems/18_sliding_window_maximum](../more_problems/18_sliding_window_maximum/) |  |

### Stack (7)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Valid Parentheses | 20 | [medium/60_balanced_brackets](../medium/60_balanced_brackets/) | Balanced Brackets |
| Min Stack | 155 | [medium/59_min_max_stack_construction](../medium/59_min_max_stack_construction/) | Min Max Stack Construction |
| Evaluate Reverse Polish Notation | 150 | [medium/65_reverse_polish_notation](../medium/65_reverse_polish_notation/) |  |
| Generate Parentheses | 22 | [hard/42_generate_div_tags](../hard/42_generate_div_tags/) | Generate Div Tags: the same backtracking with tags |
| Daily Temperatures | 739 | [neetcode/07_daily_temperatures](../neetcode/07_daily_temperatures/) |  |
| Car Fleet | 853 | [neetcode/08_car_fleet](../neetcode/08_car_fleet/) |  |
| Largest Rectangle in Histogram | 84 | [hard/52_largest_rectangle_under_skyline](../hard/52_largest_rectangle_under_skyline/) | Largest Rectangle Under Skyline |

### Binary Search (7)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Binary Search | 704 | [easy/19_binary_search](../easy/19_binary_search/) |  |
| Search a 2D Matrix | 74 | [neetcode/09_search_a_2d_matrix](../neetcode/09_search_a_2d_matrix/) |  |
| Koko Eating Bananas | 875 | [more_problems/13_koko_eating_bananas](../more_problems/13_koko_eating_bananas/) |  |
| Find Minimum in Rotated Sorted Array | 153 | [more_problems/11_find_minimum_in_rotated_sorted_array](../more_problems/11_find_minimum_in_rotated_sorted_array/) |  |
| Search in Rotated Sorted Array | 33 | [hard/44_shifted_binary_search](../hard/44_shifted_binary_search/) | Shifted Binary Search |
| Time Based Key-Value Store | 981 | [neetcode/10_time_based_key_value_store](../neetcode/10_time_based_key_value_store/) |  |
| Median of Two Sorted Arrays | 4 | [very_hard/31_median_of_two_sorted_arrays](../very_hard/31_median_of_two_sorted_arrays/) |  |

### Linked List (11)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Reverse Linked List | 206 | [hard/36_reverse_linked_list](../hard/36_reverse_linked_list/) |  |
| Merge Two Sorted Lists | 21 | [hard/37_merge_linked_lists](../hard/37_merge_linked_lists/) | Merge Linked Lists |
| Reorder List | 143 | [very_hard/27_zip_linked_list](../very_hard/27_zip_linked_list/) | Zip Linked List |
| Remove Nth Node From End of List | 19 | [medium/48_remove_kth_node_from_end](../medium/48_remove_kth_node_from_end/) |  |
| Copy List with Random Pointer | 138 | [more_problems/22_copy_list_with_random_pointer](../more_problems/22_copy_list_with_random_pointer/) |  |
| Add Two Numbers | 2 | [medium/49_sum_of_linked_lists](../medium/49_sum_of_linked_lists/) | Sum Of Linked Lists |
| Linked List Cycle | 141 | [hard/35_find_loop](../hard/35_find_loop/) | Find Loop: phase 1 of Floyd is the detection |
| Find the Duplicate Number | 287 | [more_problems/08_find_the_duplicate_number](../more_problems/08_find_the_duplicate_number/) |  |
| LRU Cache | 146 | [very_hard/24_lru_cache](../very_hard/24_lru_cache/) |  |
| Merge k Sorted Lists | 23 | [neetcode/11_merge_k_sorted_lists](../neetcode/11_merge_k_sorted_lists/) |  |
| Reverse Nodes in k-Group | 25 | [more_problems/23_reverse_nodes_in_k_group](../more_problems/23_reverse_nodes_in_k_group/) |  |

### Trees (15)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Invert Binary Tree | 226 | [medium/21_invert_binary_tree](../medium/21_invert_binary_tree/) |  |
| Maximum Depth of Binary Tree | 104 | [neetcode/12_maximum_depth_of_binary_tree](../neetcode/12_maximum_depth_of_binary_tree/) |  |
| Diameter of Binary Tree | 543 | [medium/22_binary_tree_diameter](../medium/22_binary_tree_diameter/) |  |
| Balanced Binary Tree | 110 | [medium/24_height_balanced_binary_tree](../medium/24_height_balanced_binary_tree/) |  |
| Same Tree | 100 | [neetcode/13_same_tree](../neetcode/13_same_tree/) |  |
| Subtree of Another Tree | 572 | [neetcode/14_subtree_of_another_tree](../neetcode/14_subtree_of_another_tree/) |  |
| Lowest Common Ancestor of a BST | 235 | [neetcode/15_lowest_common_ancestor_of_bst](../neetcode/15_lowest_common_ancestor_of_bst/) |  |
| Binary Tree Level Order Traversal | 102 | [neetcode/16_binary_tree_level_order_traversal](../neetcode/16_binary_tree_level_order_traversal/) |  |
| Binary Tree Right Side View | 199 | [neetcode/17_binary_tree_right_side_view](../neetcode/17_binary_tree_right_side_view/) |  |
| Count Good Nodes in Binary Tree | 1448 | [neetcode/18_count_good_nodes_in_binary_tree](../neetcode/18_count_good_nodes_in_binary_tree/) |  |
| Validate Binary Search Tree | 98 | [medium/16_validate_bst](../medium/16_validate_bst/) |  |
| Kth Smallest Element in a BST | 230 | [medium/19_find_kth_largest_value_in_bst](../medium/19_find_kth_largest_value_in_bst/) | Find Kth Largest Value In BST: the mirrored traversal |
| Construct Binary Tree from Preorder and Inorder Traversal | 105 | [more_problems/30_construct_binary_tree_from_preorder_inorder](../more_problems/30_construct_binary_tree_from_preorder_inorder/) |  |
| Binary Tree Maximum Path Sum | 124 | [hard/13_max_path_sum_in_binary_tree](../hard/13_max_path_sum_in_binary_tree/) |  |
| Serialize and Deserialize Binary Tree | 297 | [more_problems/31_serialize_and_deserialize_binary_tree](../more_problems/31_serialize_and_deserialize_binary_tree/) |  |

### Tries (3)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Implement Trie (Prefix Tree) | 208 | [neetcode/19_implement_trie](../neetcode/19_implement_trie/) |  |
| Design Add and Search Words Data Structure | 211 | [neetcode/20_design_add_and_search_words](../neetcode/20_design_add_and_search_words/) |  |
| Word Search II | 212 | [hard/30_boggle_board](../hard/30_boggle_board/) | Boggle Board |

### Heap / Priority Queue (7)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Kth Largest Element in a Stream | 703 | [neetcode/21_kth_largest_element_in_a_stream](../neetcode/21_kth_largest_element_in_a_stream/) |  |
| Last Stone Weight | 1046 | [neetcode/22_last_stone_weight](../neetcode/22_last_stone_weight/) |  |
| K Closest Points to Origin | 973 | [neetcode/23_k_closest_points_to_origin](../neetcode/23_k_closest_points_to_origin/) |  |
| Kth Largest Element in an Array | 215 | [hard/46_quickselect](../hard/46_quickselect/) | Quickselect |
| Task Scheduler | 621 | [more_problems/47_task_scheduler](../more_problems/47_task_scheduler/) |  |
| Design Twitter | 355 | [neetcode/24_design_twitter](../neetcode/24_design_twitter/) |  |
| Find Median from Data Stream | 295 | [hard/34_continuous_median](../hard/34_continuous_median/) | Continuous Median |

### Backtracking (9)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Subsets | 78 | [medium/52_powerset](../medium/52_powerset/) | Powerset |
| Combination Sum | 39 | [more_problems/24_combination_sum](../more_problems/24_combination_sum/) |  |
| Permutations | 46 | [medium/51_permutations](../medium/51_permutations/) |  |
| Subsets II | 90 | [more_problems/25_subsets_ii](../more_problems/25_subsets_ii/) |  |
| Combination Sum II | 40 | [neetcode/25_combination_sum_ii](../neetcode/25_combination_sum_ii/) |  |
| Word Search | 79 | [more_problems/26_word_search](../more_problems/26_word_search/) |  |
| Palindrome Partitioning | 131 | [more_problems/27_palindrome_partitioning](../more_problems/27_palindrome_partitioning/) |  |
| Letter Combinations of a Phone Number | 17 | [medium/53_phone_number_mnemonics](../medium/53_phone_number_mnemonics/) | Phone Number Mnemonics |
| N-Queens | 51 | [very_hard/30_non_attacking_queens](../very_hard/30_non_attacking_queens/) | Non-Attacking Queens counts boards; listing them is the same recursion |

### Graphs (13)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Number of Islands | 200 | [medium/38_river_sizes](../medium/38_river_sizes/) | River Sizes: the count of rivers |
| Clone Graph | 133 | [neetcode/26_clone_graph](../neetcode/26_clone_graph/) |  |
| Max Area of Island | 695 | [medium/38_river_sizes](../medium/38_river_sizes/) | River Sizes: the largest river |
| Pacific Atlantic Water Flow | 417 | [neetcode/27_pacific_atlantic_water_flow](../neetcode/27_pacific_atlantic_water_flow/) |  |
| Surrounded Regions | 130 | [medium/40_remove_islands](../medium/40_remove_islands/) | Remove Islands |
| Rotting Oranges | 994 | [medium/42_minimum_passes_of_matrix](../medium/42_minimum_passes_of_matrix/) | Minimum Passes Of Matrix |
| Walls and Gates | 286 | [neetcode/28_walls_and_gates](../neetcode/28_walls_and_gates/) |  |
| Course Schedule | 207 | [hard/27_topological_sort](../hard/27_topological_sort/) | Topological Sort (a cycle means false); also medium/41 Cycle In Graph |
| Course Schedule II | 210 | [hard/27_topological_sort](../hard/27_topological_sort/) | Topological Sort |
| Redundant Connection | 684 | [neetcode/29_redundant_connection](../neetcode/29_redundant_connection/) |  |
| Number of Connected Components in an Undirected Graph | 323 | [medium/35_union_find](../medium/35_union_find/) | Union Find |
| Graph Valid Tree | 261 | [neetcode/30_graph_valid_tree](../neetcode/30_graph_valid_tree/) |  |
| Word Ladder | 127 | [more_problems/33_word_ladder](../more_problems/33_word_ladder/) |  |

### Advanced Graphs (6)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Reconstruct Itinerary | 332 | [neetcode/31_reconstruct_itinerary](../neetcode/31_reconstruct_itinerary/) |  |
| Min Cost to Connect All Points | 1584 | [hard/29_prims_algorithm](../hard/29_prims_algorithm/) | Prim's; on this complete graph the O(V^2) array version beats the heap |
| Network Delay Time | 743 | [hard/26_dijkstras_algorithm](../hard/26_dijkstras_algorithm/) | Dijkstra's; the answer is the largest distance |
| Swim in Rising Water | 778 | [neetcode/32_swim_in_rising_water](../neetcode/32_swim_in_rising_water/) |  |
| Alien Dictionary | 269 | [more_problems/34_alien_dictionary](../more_problems/34_alien_dictionary/) |  |
| Cheapest Flights Within K Stops | 787 | [more_problems/35_cheapest_flights_within_k_stops](../more_problems/35_cheapest_flights_within_k_stops/) |  |

### 1-D Dynamic Programming (12)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Climbing Stairs | 70 | [medium/54_staircase_traversal](../medium/54_staircase_traversal/) | Staircase Traversal |
| Min Cost Climbing Stairs | 746 | [neetcode/33_min_cost_climbing_stairs](../neetcode/33_min_cost_climbing_stairs/) |  |
| House Robber | 198 | [medium/28_max_subset_sum_no_adjacent](../medium/28_max_subset_sum_no_adjacent/) | Max Subset Sum No Adjacent |
| House Robber II | 213 | [neetcode/34_house_robber_ii](../neetcode/34_house_robber_ii/) |  |
| Longest Palindromic Substring | 5 | [medium/67_longest_palindromic_substring](../medium/67_longest_palindromic_substring/) |  |
| Palindromic Substrings | 647 | [neetcode/35_palindromic_substrings](../neetcode/35_palindromic_substrings/) |  |
| Decode Ways | 91 | [neetcode/36_decode_ways](../neetcode/36_decode_ways/) |  |
| Coin Change | 322 | [medium/30_min_number_of_coins_for_change](../medium/30_min_number_of_coins_for_change/) | Min Number Of Coins For Change |
| Maximum Product Subarray | 152 | [more_problems/07_maximum_product_subarray](../more_problems/07_maximum_product_subarray/) |  |
| Word Break | 139 | [neetcode/37_word_break](../neetcode/37_word_break/) |  |
| Longest Increasing Subsequence | 300 | [very_hard/14_longest_increasing_subsequence](../very_hard/14_longest_increasing_subsequence/) |  |
| Partition Equal Subset Sum | 416 | [more_problems/39_partition_equal_subset_sum](../more_problems/39_partition_equal_subset_sum/) |  |

### 2-D Dynamic Programming (11)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Unique Paths | 62 | [medium/32_number_of_ways_to_traverse_graph](../medium/32_number_of_ways_to_traverse_graph/) | Number Of Ways To Traverse Graph |
| Longest Common Subsequence | 1143 | [hard/16_longest_common_subsequence](../hard/16_longest_common_subsequence/) |  |
| Best Time to Buy and Sell Stock with Cooldown | 309 | [neetcode/38_best_time_to_buy_and_sell_stock_with_cooldown](../neetcode/38_best_time_to_buy_and_sell_stock_with_cooldown/) |  |
| Coin Change II | 518 | [medium/29_number_of_ways_to_make_change](../medium/29_number_of_ways_to_make_change/) | Number Of Ways To Make Change |
| Target Sum | 494 | [neetcode/39_target_sum](../neetcode/39_target_sum/) |  |
| Interleaving String | 97 | [hard/40_interweaving_strings](../hard/40_interweaving_strings/) |  |
| Longest Increasing Path in a Matrix | 329 | [neetcode/40_longest_increasing_path_in_a_matrix](../neetcode/40_longest_increasing_path_in_a_matrix/) |  |
| Distinct Subsequences | 115 | [more_problems/41_distinct_subsequences](../more_problems/41_distinct_subsequences/) |  |
| Edit Distance | 72 | [medium/31_levenshtein_distance](../medium/31_levenshtein_distance/) | Levenshtein Distance |
| Burst Balloons | 312 | [more_problems/43_burst_balloons](../more_problems/43_burst_balloons/) |  |
| Regular Expression Matching | 10 | [neetcode/41_regular_expression_matching](../neetcode/41_regular_expression_matching/) |  |

### Greedy (8)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Maximum Subarray | 53 | [medium/33_kadanes_algorithm](../medium/33_kadanes_algorithm/) | Kadane's Algorithm |
| Jump Game | 55 | [neetcode/42_jump_game](../neetcode/42_jump_game/) |  |
| Jump Game II | 45 | [hard/17_min_number_of_jumps](../hard/17_min_number_of_jumps/) | Min Number Of Jumps |
| Gas Station | 134 | [medium/45_valid_starting_city](../medium/45_valid_starting_city/) | Valid Starting City |
| Hand of Straights | 846 | [neetcode/43_hand_of_straights](../neetcode/43_hand_of_straights/) |  |
| Merge Triplets to Form Target Triplet | 1899 | [neetcode/44_merge_triplets_to_form_target_triplet](../neetcode/44_merge_triplets_to_form_target_triplet/) |  |
| Partition Labels | 763 | [neetcode/45_partition_labels](../neetcode/45_partition_labels/) |  |
| Valid Parenthesis String | 678 | [more_problems/46_valid_parenthesis_string](../more_problems/46_valid_parenthesis_string/) |  |

### Intervals (6)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Insert Interval | 57 | [neetcode/46_insert_interval](../neetcode/46_insert_interval/) |  |
| Merge Intervals | 56 | [medium/09_merge_overlapping_intervals](../medium/09_merge_overlapping_intervals/) | Merge Overlapping Intervals |
| Non-overlapping Intervals | 435 | [more_problems/45_non_overlapping_intervals](../more_problems/45_non_overlapping_intervals/) |  |
| Meeting Rooms | 252 | [neetcode/47_meeting_rooms](../neetcode/47_meeting_rooms/) |  |
| Meeting Rooms II | 253 | [hard/32_laptop_rentals](../hard/32_laptop_rentals/) | Laptop Rentals |
| Minimum Interval to Include Each Query | 1851 | [neetcode/48_minimum_interval_to_include_each_query](../neetcode/48_minimum_interval_to_include_each_query/) |  |

### Math & Geometry (8)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Rotate Image | 48 | [more_problems/03_rotate_matrix](../more_problems/03_rotate_matrix/) |  |
| Spiral Matrix | 54 | [medium/05_spiral_traverse](../medium/05_spiral_traverse/) | Spiral Traverse |
| Set Matrix Zeroes | 73 | [more_problems/04_set_matrix_zeroes](../more_problems/04_set_matrix_zeroes/) |  |
| Happy Number | 202 | [neetcode/49_happy_number](../neetcode/49_happy_number/) |  |
| Plus One | 66 | [neetcode/50_plus_one](../neetcode/50_plus_one/) |  |
| Pow(x, n) | 50 | [neetcode/51_pow_x_n](../neetcode/51_pow_x_n/) |  |
| Multiply Strings | 43 | [neetcode/52_multiply_strings](../neetcode/52_multiply_strings/) |  |
| Detect Squares | 2013 | [neetcode/53_detect_squares](../neetcode/53_detect_squares/) |  |

### Bit Manipulation (7)

| Problem | LeetCode | Where | Note |
|---|---|---|---|
| Single Number | 136 | [neetcode/54_single_number](../neetcode/54_single_number/) |  |
| Number of 1 Bits | 191 | [neetcode/55_number_of_1_bits](../neetcode/55_number_of_1_bits/) |  |
| Counting Bits | 338 | [neetcode/56_counting_bits](../neetcode/56_counting_bits/) |  |
| Reverse Bits | 190 | [neetcode/57_reverse_bits](../neetcode/57_reverse_bits/) |  |
| Missing Number | 268 | [neetcode/58_missing_number](../neetcode/58_missing_number/) |  |
| Sum of Two Integers | 371 | [neetcode/59_sum_of_two_integers](../neetcode/59_sum_of_two_integers/) |  |
| Reverse Integer | 7 | [neetcode/60_reverse_integer](../neetcode/60_reverse_integer/) |  |
