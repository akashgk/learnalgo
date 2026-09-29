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

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  check(
    accountsMerge([
      ['John', 'johnsmith@mail.com', 'john_newyork@mail.com'],
      ['John', 'johnsmith@mail.com', 'john00@mail.com'],
      ['Mary', 'mary@mail.com'],
      ['John', 'johnnybravo@mail.com'],
    ]),
    [
      ['John', 'john00@mail.com', 'john_newyork@mail.com', 'johnsmith@mail.com'],
      ['John', 'johnnybravo@mail.com'],
      ['Mary', 'mary@mail.com'],
    ],
  );
  // Transitive: A-B share x, B-C share y, so A, B, C are one person.
  check(
    accountsMerge([
      ['Ann', 'a', 'x'],
      ['Ann', 'c', 'y'],
      ['Ann', 'x', 'y'],
    ]),
    [
      ['Ann', 'a', 'c', 'x', 'y'],
    ],
  );
}
