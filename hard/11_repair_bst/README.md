# Repair BST

**Difficulty:** Hard | **Category:** Binary Search Trees | **Pattern:** In-order traversal to find inversions

## Problem
Exactly two nodes in a BST had their values swapped, breaking the BST property. Repair the tree in place (by swapping the two values back) and return it.

## Building up the logic
1. The in-order traversal of a valid BST is sorted. Swapping two values in a sorted sequence creates:
   - **two** inversions (`a[i] > a[i+1]`) if the swapped elements are not adjacent: `1 2 [8] 4 5 [3] 9`;
   - **one** inversion if they are adjacent in the sequence: `1 [3] [2] 4`.
2. The first misplaced node is the **larger** element of the first inversion (`prev`), and the second is the **smaller** element of the last inversion (`current`). Setting `second` at every inversion and `first` only once handles both cases uniformly.
3. Swap the two values.
4. Collecting the in-order values into an array first also works but costs O(n) extra space; tracking `prev` during traversal avoids it.

## Complexity
- Time: O(n).
- Space: O(h) for the traversal stack. **Morris traversal** makes it O(1) (the LeetCode #99 follow-up).

## Interview notes
- Walk through the adjacent-swap case explicitly; missing it is the common bug.
