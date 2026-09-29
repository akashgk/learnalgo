# Find Nodes Distance K

**Difficulty:** Hard | **Category:** Binary Trees | **Pattern:** Tree -> undirected graph, then BFS

## Problem
Given a binary tree with unique values, a target value present in the tree, and a non-negative integer k, return the values of all nodes exactly k edges away from the target node, in any order.

## Building up the logic
1. Nodes below the target are easy (go down k levels). The difficulty is nodes reached by going **up** through ancestors and then down other branches.
2. Children pointers only go down. Add the missing direction: record every node's **parent** in a hash map with one traversal.
3. Now the tree is an undirected graph (edges to left, right, parent). "All nodes at distance k" is BFS for k levels from the target, with a visited set so you never walk back the way you came.
4. After k levels, the frontier is the answer.

## Alternative (no extra map)
Recursive: find the target; collect nodes k levels below it. On the way back up, each ancestor at distance `d` from the target contributes itself if `d == k`, and nodes `k - d - 1` levels down its **other** subtree. O(n) time, O(h) space. Harder to get right under pressure; the parent-map BFS is safer.

## Complexity
- Time: O(n).
- Space: O(n) for the parent map and visited set.

## Interview notes
- LeetCode #863 (All Nodes Distance K in Binary Tree). "Convert the tree to a graph" is a strong general move whenever a tree problem needs upward movement.
- Dart note: `.nonNulls` filters nulls from an iterable and gives a non-nullable type.
