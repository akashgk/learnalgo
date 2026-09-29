# Stable Internships

**Difficulty:** Medium | **Category:** Famous Algorithms | **Pattern:** Gale-Shapley stable matching

## Problem
There are `n` interns and `n` teams. Each intern ranks all teams, and each team ranks all interns. Produce a one-to-one matching that is **stable**: there is no intern and team who both prefer each other over their assigned partners. Among stable matchings, return the one that is best for the interns. Output pairs `[intern, team]`.

## Building up the logic
1. Checking all n! matchings for stability is hopeless.
2. **Gale-Shapley (deferred acceptance):**
   - Every free intern proposes to their most-preferred team they have not proposed to yet.
   - A team tentatively holds its best proposal so far; if a better intern proposes, the team swaps and the previous intern becomes free again.
   - Repeat until nobody is free.
3. **Why it terminates:** each intern proposes to each team at most once, so at most n^2 proposals.
4. **Why it is stable:** suppose intern i prefers team t over their final team. Then i proposed to t earlier and t rejected or later dropped i for someone t preferred. Teams only ever trade up, so t ends with someone it prefers to i. No blocking pair.
5. **Why intern-optimal:** the proposing side gets its best partner among all stable matchings (a known theorem; state it, you will not need to prove it in an interview).
6. Precompute each team's rank table so "does team t prefer i over j?" is O(1). Without it, each comparison is O(n) and the algorithm is O(n^3).

## Complexity
- Time: O(n^2).
- Space: O(n^2) for the rank tables.

## Interview notes
- Real uses: the US medical residency match (NRMP), school admissions. Lloyd Shapley and Alvin Roth won the 2012 Nobel in Economics for this line of work.
