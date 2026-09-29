# Same BSTs

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** Recursive structure comparison without building trees

## Problem
Two arrays each represent a sequence of insertions into an empty BST (duplicates go right). Without constructing the BSTs, determine whether both sequences produce the same tree.

## Building up the logic
1. Building both trees and comparing is O(n^2) worst case and O(n) space; the problem forbids it to test your understanding of insertion order.
2. **Observation:** the first element is the root. Then the elements smaller than the root, in their original relative order, form exactly the insertion sequence of the left subtree; the elements `>=` the root form the right subtree's sequence.
3. So: roots equal, lengths equal, and recursively the "smaller" subsequences produce the same BST and the "bigger or equal" subsequences produce the same BST.
4. **Simple version:** build the two subsequence arrays at each level. O(n^2) time and O(n^2) space.
5. **Space-optimized version (this code):** never copy. Represent a subtree by the index of its root in each array plus the value bounds `[min, max)` it must respect. The root of the left subtree is the first later element that is smaller than the current root and within bounds; similarly for the right. O(n^2) time, O(d) space where d is the tree depth.

## Complexity
- Time: O(n^2): each recursive call scans forward to find children.
- Space: O(d) recursion (O(n) worst case).

## Interview notes
- The "insertion order determines structure via relative order of smaller/larger elements" insight is the whole problem. Draw both trees for a small example to see why interleaving the left and right subsequences does not matter.
