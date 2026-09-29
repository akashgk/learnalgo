# All Kinds Of Node Depths

**Difficulty:** Very Hard | **Category:** Binary Trees | **Pattern:** Bottom-up aggregation with subtree sizes

## Problem
For every node, treat it as the root of its own subtree and compute the sum of depths of all nodes in that subtree (Node Depths). Return the sum of these values over all nodes.

```
         1
       /   \
      2     3
     / \   / \
    4   5 6   7
   / \
  8   9          ->  26
```

## Building up the logic
1. Brute force: run Node Depths from every node: O(n^2) worst case (O(n log n) for balanced trees).
2. **Key relation:** if you know a child's subtree depth sum `D(child)` and size `S(child)`, then measured from the parent, every node in that subtree is one level deeper: it contributes `D(child) + S(child)`.
3. So `D(node) = D(left) + S(left) + D(right) + S(right)`, computed bottom-up in O(1) per node.
4. The requested answer is the sum of `D(node)` over all nodes, also accumulated bottom-up.

Alternative insight: each node at depth d contributes `0 + 1 + ... + d = d(d+1)/2` (its depth measured from each ancestor, including itself). Summing `d(d+1)/2` over all nodes with a single traversal gives the same answer. Two very different derivations of one number; either is a strong answer.

## Complexity
- Time: O(n).
- Space: O(h).

## Interview notes
- LeetCode #834 (Sum of Distances in Tree) is the harder cousin: distances from every node to all other nodes (not just its subtree), solved with a second top-down "rerooting" pass.
