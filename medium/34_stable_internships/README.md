# Stable Internships

**Difficulty:** Medium | **Category:** Famous Algorithms | **Pattern:** Gale-Shapley stable matching

## The problem

There are `n` interns and `n` teams. Each intern ranks all teams, and each team ranks all interns (best first). Produce a one-to-one matching that is **stable**: there must be no intern and team who both prefer each other over the partners they were matched with. Among all stable matchings, return the one that is best for the interns. Output a list of `[intern, team]` pairs.

```
interns = [[0, 1, 2], [0, 2, 1], [1, 2, 0]]   (intern i's team preferences)
teams   = [[2, 1, 0], [1, 2, 0], [0, 2, 1]]   (team t's intern preferences)
->  [[0, 2], [1, 0], [2, 1]]
```

## Step 1: What "stable" means

A pair (intern i, team t) is a **blocking pair** if i prefers t over i's assigned team **and** t prefers i over t's assigned intern. Both would happily break their assignments to be together, so the matching would not hold. A stable matching has no blocking pair.

## Step 2: Brute force

Try all n! matchings and test each for blocking pairs (O(n^2) per test). Hopeless beyond tiny n.

## Step 3: Gale-Shapley (deferred acceptance)

1. All interns start free.
2. A free intern **proposes** to the most preferred team they have not proposed to yet.
3. The team:
   - if it has no intern, tentatively accepts;
   - if it prefers the new intern to its current one, it swaps, and the old intern becomes free again;
   - otherwise it rejects the proposal.
4. Repeat until no intern is free.

Acceptances are only **tentative** ("deferred"): a team may trade up later.

### Why it terminates

Each intern proposes to each team at most once, so there are at most n^2 proposals.

### Why the result is stable

Suppose intern i prefers team t over the team i ended with. Then i proposed to t earlier (interns propose in preference order). Team t either rejected i or later dropped i, and in both cases it did so for an intern it preferred. Teams only ever trade **up**, so t ends with someone it prefers to i. So (i, t) is not a blocking pair.

### Why it is intern-optimal

A known theorem: the proposing side gets its best possible partner among all stable matchings (and the receiving side gets its worst). You do not need to prove it in an interview; stating it is enough.

## Step 4: Implementation details that matter

- **Rank table:** "does team t prefer intern a over intern b?" is asked at every proposal. Scanning t's list is O(n), making the algorithm O(n^3). Precompute `rank[t][intern] = position in t's list` once, so each comparison is O(1): overall O(n^2).
- **Next choice pointer:** `nextChoice[i]` = index of the next team intern i will propose to.
- **Free queue:** interns waiting to propose.

## Step 5: The code

<!-- CODE:START -->

Full source: [`stable_internships.dart`](stable_internships.dart) (run it with `dart run`).

```dart
// Stable Internships: Gale-Shapley stable matching with interns proposing.
// interns[i] = team preferences of intern i (best first); teams[t] = intern preferences.
// Returns [intern, team] pairs. O(n^2) time, O(n^2) space.

import 'dart:collection';

List<List<int>> stableInternships(List<List<int>> interns, List<List<int>> teams) {
  final n = interns.length;
  // rank[t][i] = position of intern i in team t's list (lower is better): O(1) comparisons.
  final rank = [
    for (final prefs in teams) {for (var pos = 0; pos < prefs.length; pos++) prefs[pos]: pos},
  ];
  final nextChoice = List<int>.filled(n, 0); // next team each intern will propose to
  final teamMatch = List<int?>.filled(n, null); // teamMatch[t] = intern currently held
  final free = Queue<int>.of(List.generate(n, (i) => i));

  while (free.isNotEmpty) {
    final intern = free.removeFirst();
    final team = interns[intern][nextChoice[intern]++];
    final current = teamMatch[team];
    if (current == null) {
      teamMatch[team] = intern;
    } else if (rank[team][intern]! < rank[team][current]!) {
      teamMatch[team] = intern;
      free.add(current); // bumped intern proposes to their next choice later
    } else {
      free.add(intern);
    }
  }
  return [
    for (var t = 0; t < n; t++) [teamMatch[t]!, t],
  ]..sort((a, b) => a[0] - b[0]);
}
```

<!-- CODE:END -->

### Walkthrough

- `rank` is a list of maps: `rank[t][i]` is intern i's position in team t's preferences.
- `nextChoice[intern]++` reads the next team and advances the pointer in one step.
- `teamMatch[team]` holds the intern currently tentatively accepted (or null).
- A bumped or rejected intern goes back into `free`.
- The output is sorted by intern.

## Step 6: Dry run

| proposal | team's current | team prefers? | result | free interns |
|---|---|---|---|---|
| i0 -> t0 | none | | t0 holds i0 | i1, i2 |
| i1 -> t0 | i0 | t0 ranks i1 (1) above i0 (2): yes | t0 holds i1, i0 freed | i2, i0 |
| i2 -> t1 | none | | t1 holds i2 | i0 |
| i0 -> t1 | i2 | t1 ranks i2 (1) above i0 (2): keep i2 | reject | i0 |
| i0 -> t2 | none | | t2 holds i0 | none |

Result: `[[0, 2], [1, 0], [2, 1]]`. The test also runs an independent checker that confirms there is no blocking pair.

## Complexity

- **Time: O(n^2)**: at most n^2 proposals, each O(1) with the rank table.
- **Space: O(n^2)** for the rank tables (the input itself is O(n^2)).

## Common mistakes

- Treating acceptance as final (no swapping): the result may not be stable.
- O(n) preference lookups (forgetting the rank table).

## Real-world note

This algorithm (and its variants) matches medical residents to hospitals in the US (NRMP) and students to schools in several cities. Lloyd Shapley and Alvin Roth received the 2012 Nobel Prize in Economics for this work.

## What to remember

Proposers propose in preference order; receivers hold their best offer and trade up. It always terminates with a stable matching that is optimal for the proposers.
