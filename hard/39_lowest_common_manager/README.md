# Lowest Common Manager

**Difficulty:** Hard | **Category:** Recursion | **Pattern:** Post-order counting (lowest common ancestor without parent pointers)

## The problem

An org chart is a tree: each manager has a list of **direct reports**. Given the top manager and two reports (both somewhere in the chart), return their **lowest common manager**: the deepest manager who has both reports in their hierarchy. A manager counts as being in their own hierarchy (so if one report manages the other, that report is the answer).

```
            A
         /     \
        B       C
      /   \   /   \
     D     E F     G
    / \
   H   I

LCM(E, I) = B     LCM(H, G) = A     LCM(D, I) = D     LCM(F, F) = F
```

## Step 1: Why this differs from Youngest Common Ancestor

In Youngest Common Ancestor (medium 39), each node had a **parent pointer**, so we could walk upward. Here we only have pointers **downward** (direct reports). Information must flow **bottom-up** through recursion instead.

## Step 2: What each subtree should report

Let every call answer one question: **how many of the two target reports are in my hierarchy?** (0, 1, or 2.)

```
count(manager) = (sum of count(report) for each direct report)
               + (1 if manager is reportOne) + (1 if manager is reportTwo)
```

The **first** manager (in post-order, which means the deepest) whose count reaches 2 is the lowest common manager. Every manager above it also has count 2, so record only the first one.

Early exit: once found, stop exploring other subtrees.

## Step 3: The code

<!-- CODE:START -->

Full source: [`lowest_common_manager.dart`](lowest_common_manager.dart) (run it with `dart run`).

```dart
// Lowest Common Manager in an org chart (n-ary tree, no parent pointers).
// Post-order: each subtree reports how many of the two reports it contains; the first node
// whose subtree contains both is the answer. O(n) time, O(d) space.

class OrgChart {
  OrgChart(this.name, [List<OrgChart>? directReports]) : directReports = directReports ?? [];
  final String name;
  final List<OrgChart> directReports;
}

OrgChart getLowestCommonManager(OrgChart topManager, OrgChart reportOne, OrgChart reportTwo) {
  OrgChart? answer;

  int countReports(OrgChart manager) {
    var count = 0;
    for (final report in manager.directReports) {
      count += countReports(report);
      if (answer != null) return 2; // already found deeper: stop exploring
    }
    if (identical(manager, reportOne)) count++;
    if (identical(manager, reportTwo)) count++;
    if (count == 2) answer ??= manager;
    return count;
  }

  countReports(topManager);
  return answer!;
}
```

<!-- CODE:END -->

### Walkthrough

- `answer` is set once, by the deepest manager whose count reaches 2 (`answer ??= manager`).
- `countReports(manager)` sums the counts of its direct reports, then adds 1 for each target that is the manager itself.
- `if (answer != null) return 2;` stops further work once the answer is known.
- When both targets are the same person (`F, F`), that manager adds 2 for itself and becomes the answer.

## Step 4: Dry run: LCM(E, I)

| manager | counts from reports | self? | total |
|---|---|---|---|
| H | | no | 0 |
| I | | yes (reportTwo) | 1 |
| D | 0 + 1 | no | 1 |
| E | | yes (reportOne) | 1 |
| B | 1 + 1 | no | **2** -> answer B |

## Complexity

- **Time: O(n)**: each manager is visited at most once.
- **Space: O(d)**, the depth of the org chart (recursion stack).

## Common mistakes

- Returning the first manager with count >= 1 (too deep).
- Returning the root when the answer is lower (not stopping at the **first** count of 2).
- Forgetting that a manager can be one of the two reports.

## Follow-ups

1. **Lowest Common Ancestor of a Binary Tree (LeetCode #236):** same idea; a common formulation returns the node itself if it is a target, and a node is the answer if targets are found in two different subtrees.
2. **LCA in a BST (#235):** walk down from the root using values.
3. **Many LCA queries:** binary lifting, or Euler tour + range minimum query.

## What to remember

Without parent pointers, compute bottom-up: each subtree reports how many targets it contains; the deepest node that reaches "both" is the answer.
