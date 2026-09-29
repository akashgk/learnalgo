# Topological Sort

**Difficulty:** Hard | **Category:** Famous Algorithms | **Pattern:** Kahn's algorithm (in-degree BFS) or DFS post-order

## The problem

You get a list of job ids and a list of dependencies `[prereq, job]`, meaning `prereq` must run before `job`. Return any order in which all jobs can run, or `[]` if it is impossible (the dependencies contain a cycle).

```
jobs = [1, 2, 3, 4], deps = [[1, 2], [1, 3], [3, 2], [4, 2], [4, 3]]
->  e.g. [1, 4, 3, 2]
```

## Step 1: Model as a graph

Jobs are vertices; a dependency `prereq -> job` is a directed edge. A valid order puts every edge's source before its target: a **topological ordering**. It exists exactly when the graph has **no cycle** (a directed acyclic graph, DAG). With a cycle `A -> B -> A`, neither can go first.

## Step 2: Kahn's algorithm (BFS on in-degrees)

A job with **no unmet prerequisites** (in-degree 0) can run now.

1. Compute every job's in-degree (number of prerequisites).
2. Put all in-degree-0 jobs in a queue.
3. Repeatedly take a job from the queue, append it to the order, and "remove" its outgoing edges: decrement each dependent's in-degree; any dependent reaching 0 joins the queue.
4. If the order contains every job, return it. Otherwise, the leftover jobs are on (or behind) a cycle: return `[]`.

## Step 3: The DFS alternative

Run DFS with the three-color scheme from Cycle In Graph (medium 41). Append each job to a list when it **finishes** (post-order); reverse the list at the end. A job finishes only after everything that depends on it has finished, so reversing puts prerequisites first. A grey-to-grey edge means a cycle.

Both are O(j + d). Kahn's is iterative and naturally detects cycles by counting.

## Step 4: The code

<!-- CODE:START -->

Full source: [`topological_sort.dart`](topological_sort.dart) (run it with `dart run`).

```dart
// Topological Sort: order jobs so every [prereq, job] dependency is respected; [] if a cycle
// makes it impossible. Kahn's algorithm (BFS on in-degree 0). O(j + d) time and space.

import 'dart:collection';

List<int> topologicalSort(List<int> jobs, List<List<int>> deps) {
  final next = {for (final j in jobs) j: <int>[]};
  final inDegree = {for (final j in jobs) j: 0};
  for (final [pre, job] in deps) {
    next[pre]!.add(job);
    inDegree[job] = inDegree[job]! + 1;
  }
  final ready = Queue<int>.of(jobs.where((j) => inDegree[j] == 0));
  final order = <int>[];
  while (ready.isNotEmpty) {
    final job = ready.removeFirst();
    order.add(job);
    for (final dependent in next[job]!) {
      inDegree[dependent] = inDegree[dependent]! - 1;
      if (inDegree[dependent] == 0) ready.add(dependent);
    }
  }
  return order.length == jobs.length ? order : [];
}

bool respects(List<int> order, List<List<int>> deps) {
  final pos = {for (var i = 0; i < order.length; i++) order[i]: i};
  return deps.every((d) => pos[d[0]]! < pos[d[1]]!);
}
```

<!-- CODE:END -->

### Walkthrough

- `next[job]` lists jobs that depend on `job`; `inDegree[job]` counts its prerequisites.
- `ready` starts with every job with no prerequisites.
- Processing a job appends it and decrements its dependents.
- `order.length == jobs.length` is the cycle check.
- `respects` (test helper) verifies that every dependency is satisfied, since several orders can be valid.

## Step 5: Dry run

In-degrees: 1: 0, 2: 3 (from 1, 3, 4), 3: 2 (from 1, 4), 4: 0.

| queue | take | order | in-degree updates | newly ready |
|---|---|---|---|---|
| 1, 4 | 1 | [1] | 2: 2, 3: 1 | |
| 4 | 4 | [1, 4] | 2: 1, 3: 0 | 3 |
| 3 | 3 | [1, 4, 3] | 2: 0 | 2 |
| 2 | 2 | [1, 4, 3, 2] | | |

All 4 jobs placed: `[1, 4, 3, 2]`.

## Complexity

- **Time: O(j + d)**: each job is enqueued once and each dependency is processed once.
- **Space: O(j + d)** for the graph.

## Common mistakes

- Reversing the edge direction (placing dependents before prerequisites).
- Forgetting the cycle check.
- In the DFS version, recording the job on entry instead of on finish.

## Follow-ups

1. **Course Schedule I and II (LeetCode #207, #210).**
2. **Alien Dictionary (#269):** derive edges from adjacent words in a sorted dictionary, then topological sort.
3. **Lexicographically smallest order:** use a min-heap instead of a queue.
4. **Parallel scheduling (minimum number of semesters, #1136):** process Kahn's algorithm level by level; the number of levels is the answer.
5. **Real systems:** build tools (make, Bazel), package managers, spreadsheet recalculation.

## What to remember

Dependencies = directed edges. Kahn's algorithm repeatedly takes jobs with in-degree 0; if some jobs are never freed, there is a cycle.
