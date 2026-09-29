# Depth-first Search

**Difficulty:** Easy | **Category:** Graphs | **Pattern:** DFS traversal

## Problem
A `Node` has a name and a list of children, forming an acyclic tree-like graph. Implement `depthFirstSearch` on the class: traverse from the node, always going deep before going wide (children visited left to right), and return the names in visit order.

## Building up the logic
1. DFS = "visit me, then fully explore each child before moving to the next child". That is recursion, or an explicit stack.
2. Recursive template: add own name; for each child, recurse, passing the same output list.
3. Iterative template: stack of nodes; pop, record, push children **in reverse** so the leftmost child is popped first.
4. On a general graph (cycles possible) you must also keep a `visited` set. Here the structure is acyclic so it is unnecessary; say that explicitly in an interview.

## Complexity
- Time: O(v + e): every vertex is visited once and every edge (parent-child link) is followed once.
- Space: O(v) for the output list; the call stack is O(depth), which is O(v) in the worst case.

## Interview notes
- DFS is the backbone of: connected components (River Sizes), cycle detection (Cycle In Graph), topological sort, backtracking (Permutations, Sudoku). Being able to write both recursive and iterative DFS without hesitation is non-negotiable at FAANG.
- DFS vs BFS: DFS uses O(depth) memory and finds *a* path; BFS uses O(width) memory and finds the *shortest* path in unweighted graphs.
