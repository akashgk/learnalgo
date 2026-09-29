# Youngest Common Ancestor

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Lowest common ancestor with parent pointers

## The problem

In an ancestral tree, every node has a pointer to its direct ancestor (its parent); the top ancestor has none. Given the top ancestor and two descendants, return their **youngest common ancestor**: the deepest node that is an ancestor of both. A node counts as its own ancestor.

```
            A
         /     \
        B       C
      /   \   /   \
     D     E F     G
    / \
   H   I

YCA(E, I) = B     YCA(H, G) = A     YCA(H, I) = D     YCA(B, H) = B
```

## Step 1: Work an example by hand

For E and I: E's ancestors going up are E, B, A. I's are I, D, B, A. The first ancestor they share, going up, is B.

## Step 2: Hash set approach

Walk from `one` to the top, putting every ancestor in a set. Then walk up from `two`; the first node already in the set is the answer. **O(d) time, O(d) space**, where d is the depth.

## Step 3: O(1) space

Observation: if both nodes were at the **same depth**, you could move both up one step at a time, and they would meet exactly at the youngest common ancestor (they reach each ancestor level simultaneously).

So:

1. Compute both depths (walk up to the top, counting).
2. Move the deeper node up by the difference.
3. Move both up together until they are the same node.

For E (depth 2) and I (depth 3): move I up once to D. Now E and D are both at depth 2. Step both: B and B. They meet at B.

## Step 4: The code

<!-- CODE:START -->

Full source: [`youngest_common_ancestor.dart`](youngest_common_ancestor.dart) (run it with `dart run`).

```dart
// Youngest Common Ancestor in an ancestral tree (each node has an `ancestor` pointer).
// Equalize depths, then climb together. O(d) time, O(1) space.

class AncestralTree {
  AncestralTree(this.name, [this.ancestor]);
  final String name;
  AncestralTree? ancestor;
}

AncestralTree youngestCommonAncestor(AncestralTree top, AncestralTree one, AncestralTree two) {
  int depth(AncestralTree node) {
    var d = 0;
    for (var n = node; !identical(n, top); n = n.ancestor!) {
      d++;
    }
    return d;
  }

  var a = one, b = two;
  var da = depth(a), db = depth(b);
  while (da > db) {
    a = a.ancestor!;
    da--;
  }
  while (db > da) {
    b = b.ancestor!;
    db--;
  }
  while (!identical(a, b)) {
    a = a.ancestor!;
    b = b.ancestor!;
  }
  return a;
}
```

<!-- CODE:END -->

### Walkthrough

- `depth(node)` counts steps up to `top`.
- The two `while` loops equalize depths.
- `while (!identical(a, b))` moves both up in lockstep. `identical` compares node identity, which is what "same node" means.
- Because a node is its own ancestor, if one node is an ancestor of the other, equalizing depths already makes them identical (for example YCA(B, H) = B).

## Step 5: Dry run: YCA(H, G)

| step | a | b | depths |
|---|---|---|---|
| start | H | G | 3, 2 |
| equalize | D | G | 2, 2 |
| lockstep | B | C | 1, 1 |
| lockstep | A | A | stop |

Answer: A.

## Complexity

- **Time: O(d)**, d = depth of the deeper node.
- **Space: O(1)**.

## Common mistakes

- Moving both nodes up before equalizing depths (they pass each other's ancestors at different times and never meet correctly).
- Comparing by name instead of identity.

## Follow-ups

1. **Intersection of Two Linked Lists (LeetCode #160):** parent pointers turn each node's ancestry into a linked list, and the two lists merge at the answer. The trick "walk list A then B, and B then A" also works here without computing depths.
2. **No parent pointers, binary tree (#236):** post-order recursion (see Lowest Common Manager, hard 39).
3. **BST (#235):** walk down from the root: the first node whose value lies between the two targets.
4. **Many queries:** binary lifting (precompute 2^k-th ancestors) answers each query in O(log n).

## What to remember

With parent pointers, LCA = equalize depths, then climb in lockstep until the nodes meet.
