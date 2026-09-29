# Accounts Merge

**Difficulty:** Medium | **Category:** Graphs | **Pattern:** Union-find (disjoint set union) keyed by shared attributes | **Source:** LeetCode 721; Striver A2Z

## The problem

Each account is `[name, email1, email2, ...]`. Two accounts belong to the same person if they share **any** email (and the relation is transitive). Merge each person's accounts into `[name, ...all emails sorted]`. Two different people may have the same name.

```
[John, johnsmith@mail.com, john_newyork@mail.com]
[John, johnsmith@mail.com, john00@mail.com]
[Mary, mary@mail.com]
[John, johnnybravo@mail.com]

->  [John, john00@mail.com, john_newyork@mail.com, johnsmith@mail.com]
    [John, johnnybravo@mail.com]
    [Mary, mary@mail.com]
```

The two "John"s are different people: they share no email.

## Step 1: See the graph

Accounts are nodes. Two accounts are connected if they share an email. A person is a **connected component**. Transitivity matters: if A shares an email with B, and B shares a different email with C, then A, B and C are one person, even though A and C share nothing.

Names cannot be used to merge (different people can share a name).

## Step 2: Options

**DFS/BFS on an email graph.** Connect each account's first email to its other emails, then find components. Works, O(E log E) with sorting.

**Union-find.** Walk the accounts; for each email, remember the first account that listed it. When a later account lists the same email, **union** the two accounts. Afterwards, group every email under the root of its owner account. This is the most direct translation of "merge whenever there is overlap", and it is the typical answer.

## Step 3: Union-find refresher

- `parent[i]` points toward the representative (root) of `i`'s set.
- `find(x)`: follow parents to the root. **Path compression** (here, path halving: `parent[x] = parent[parent[x]]` while walking) keeps trees flat.
- `union(a, b)`: `parent[find(a)] = find(b)`.

With path compression (and ideally union by rank), each operation is almost O(1) amortized (inverse Ackermann). See AlgoExpert medium 35 Union Find.

## Step 4: The code

<!-- CODE:START -->

Full source: [`accounts_merge.dart`](accounts_merge.dart) (run it with `dart run`).

```dart
// Accounts Merge: each account is [name, email, email, ...]. Accounts sharing any email belong
// to the same person. Merge them; output [name, ...sorted emails], accounts sorted for determinism.
// Union-find over account indices keyed by email. O(E log E) time (sorting), O(E) space.

List<List<String>> accountsMerge(List<List<String>> accounts) {
  final parent = [for (var i = 0; i < accounts.length; i++) i];
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]]; // path halving
      x = parent[x];
    }
    return x;
  }

  final owner = <String, int>{}; // email -> first account index that listed it
  for (var i = 0; i < accounts.length; i++) {
    for (final email in accounts[i].skip(1)) {
      final j = owner[email];
      if (j == null) {
        owner[email] = i;
      } else {
        parent[find(i)] = find(j); // same email: same person
      }
    }
  }
  final groups = <int, Set<String>>{};
  owner.forEach((email, i) => groups.putIfAbsent(find(i), () => {}).add(email));
  final result = [
    for (final MapEntry(key: root, value: emails) in groups.entries) [accounts[root][0], ...(emails.toList()..sort())],
  ];
  result.sort((a, b) => a.join().compareTo(b.join()));
  return result;
}
```

<!-- CODE:END -->

### Walkthrough

- `owner[email]` is the first account index that listed the email.
- When an email is seen again in account `i`, union `i` with its owner.
- After all unions, each email is added to the group of `find(owner)`.
- The name is taken from the root account; all accounts in a group have the same name (guaranteed by the problem).
- Emails are sorted per group; the final `sort` of groups only makes the output deterministic for testing.

## Step 5: Dry run (transitive case)

Accounts: `0: [Ann, a, x]`, `1: [Ann, c, y]`, `2: [Ann, x, y]`.

| account | email | owner before | action |
|---|---|---|---|
| 0 | a | none | owner[a] = 0 |
| 0 | x | none | owner[x] = 0 |
| 1 | c | none | owner[c] = 1 |
| 1 | y | none | owner[y] = 1 |
| 2 | x | 0 | union(2, 0): parent[2] = 0 |
| 2 | y | 1 | union(2, 1): parent[find(2) = 0] = 1 |

All three accounts now have root 1. Group: `{a, x, c, y}`, sorted `[a, c, x, y]`: `[Ann, a, c, x, y]`.

## Complexity

Let E be the total number of emails.

- Time: **O(E * alpha(n) + E log E)**: near-constant union-find operations, plus sorting the emails.
- Space: **O(E + n)**.

## Edge cases

- An account with one email: its own group unless the email appears elsewhere.
- The same email twice in one account: `union(i, i)` is harmless.
- Same name, no shared email: separate people.

## Common mistakes

- Merging by name.
- Only merging accounts that share an email **directly** (missing transitivity): union-find handles it automatically.
- Forgetting to sort the emails.

## Follow-ups you should be ready for

1. **Number of Provinces (LeetCode 547), Number of Connected Components (LeetCode 323).** Plain union-find or DFS.
2. **Redundant Connection (LeetCode 684).** The first edge whose endpoints are already connected.
3. **Similar String Groups, Most Stones Removed (LeetCode 839, 947).** "Union whenever two items share an attribute" in other forms.

## What to remember

"Merge things that overlap, transitively" is union-find. Key the unions by the shared attribute (here, the email), then group by root.
