# Expense Sharing (Splitwise): Low-Level Design

## 1. Scope for the LLD round

- A **group** of members adds expenses: one payer, an amount in integer minor units, a currency, a set of participants and a **split strategy**: equal, exact amounts, percentages, or shares.
- Splits always sum exactly to the amount; leftover cents are assigned deterministically (largest remainder method).
- **Balances**: net per member and currency, and pairwise "who owes whom" before simplification.
- **Edit and delete** expenses with optimistic versioning; balances are adjusted by reversing the old effect.
- **Settle up** (record a payment).
- **Debt simplification**: greedy matching of the largest creditor and debtor, at most `n - 1` payments.

Out of scope: users and auth, notifications, currency conversion (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `SplitStrategy` (interface) | `split(amount, participants)` -> owed amount per participant. |
| `EqualSplit`, `ExactSplit`, `PercentSplit`, `ShareSplit` | The four split rules; validation; rounding. |
| `largestRemainder` | Shared rounding helper for proportional splits. |
| `Expense` | Payer, amount, currency, computed shares, version, deleted flag. |
| `Transfer` | A suggested or recorded payment: from, to, amount. |
| `Group` | Members, expenses, payments, net and pairwise balances, `simplify`. |

```text
Group --has many--> Expense --computed by--> SplitStrategy (interface)
  |                                            <-- EqualSplit, ExactSplit, PercentSplit, ShareSplit
  +--net balances: (user, currency) -> int        +--pairwise: (debtor, creditor, currency) -> int
  +--simplify(currency) -> List<Transfer>
```

## 3. Design decisions and why

- **Strategy pattern for splits:** each rule validates its own input and owns its rounding. Adding "split by itemized receipt" is a new class.
- **Integer minor units** and the **largest remainder method:** floor every proportional share, then give the remaining cents to the participants with the largest fractional parts (ties in participant order). Results always sum to the amount and are reproducible.
- **Net balances as the primary state for simplification:** only net positions matter for settling; who paid for what is history. Positive net = the group owes you.
- **Expenses keep their computed shares**, so edits and deletes reverse exactly what was applied (no recomputation drift).
- **Versions on expenses:** an edit based on an old version is rejected rather than silently overwriting someone else's change.
- **Greedy simplification:** each step settles at least one person completely, so at most `n - 1` transfers. Not always the minimum (that problem is NP-hard); state this.

## 4. The code

```dart
import 'dart:math';

// ---------- Splits ----------

class SplitException implements Exception {
  SplitException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Splits [amount] proportionally to [weights]: floors first, then leftover units to the largest remainders.
Map<String, int> largestRemainder(int amount, Map<String, int> weights) {
  final total = weights.values.fold(0, (a, b) => a + b);
  if (total <= 0) throw SplitException('weights must be positive');
  final result = <String, int>{};
  final remainders = <(String, int, int)>[]; // (user, remainder, order)
  var assigned = 0, order = 0;
  for (final MapEntry(key: user, value: w) in weights.entries) {
    if (w < 0) throw SplitException('negative weight for $user');
    result[user] = amount * w ~/ total;
    assigned += result[user]!;
    remainders.add((user, amount * w % total, order++));
  }
  remainders.sort((a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$3.compareTo(b.$3));
  for (var i = 0; i < amount - assigned; i++) {
    final user = remainders[i].$1;
    result[user] = result[user]! + 1;
  }
  return result;
}

abstract interface class SplitStrategy {
  Map<String, int> split(int amount, List<String> participants);
}

class EqualSplit implements SplitStrategy {
  const EqualSplit();
  @override
  Map<String, int> split(int amount, List<String> participants) =>
      largestRemainder(amount, {for (final p in participants) p: 1});
}

class ExactSplit implements SplitStrategy {
  const ExactSplit(this.amounts);
  final Map<String, int> amounts;
  @override
  Map<String, int> split(int amount, List<String> participants) {
    if (amounts.keys.toSet().difference(participants.toSet()).isNotEmpty) {
      throw SplitException('amounts given for non-participants');
    }
    final sum = amounts.values.fold(0, (a, b) => a + b);
    if (sum != amount) throw SplitException('exact amounts sum to $sum, expected $amount');
    return {for (final p in participants) p: amounts[p] ?? 0};
  }
}

/// Percentages in basis points (5000 = 50%), so no floating point is involved.
class PercentSplit implements SplitStrategy {
  const PercentSplit(this.basisPoints);
  final Map<String, int> basisPoints;
  @override
  Map<String, int> split(int amount, List<String> participants) {
    final total = basisPoints.values.fold(0, (a, b) => a + b);
    if (total != 10000) throw SplitException('percentages sum to ${total / 100}%, expected 100%');
    return largestRemainder(amount, {for (final p in participants) p: basisPoints[p] ?? 0});
  }
}

class ShareSplit implements SplitStrategy {
  const ShareSplit(this.shares);
  final Map<String, int> shares;
  @override
  Map<String, int> split(int amount, List<String> participants) =>
      largestRemainder(amount, {for (final p in participants) p: shares[p] ?? 0});
}

// ---------- Group ----------

class Expense {
  Expense(this.id, this.paidBy, this.amount, this.currency, this.shares, this.description);
  final String id;
  final String paidBy;
  final int amount;
  final String currency;
  final Map<String, int> shares;
  final String description;
  var version = 1;
  var deleted = false;
}

class Transfer {
  const Transfer(this.from, this.to, this.amount);
  final String from;
  final String to;
  final int amount;
  @override
  String toString() => '$from->$to:$amount';
}

class StaleVersionException implements Exception {}

class Group {
  Group(Iterable<String> members) : members = Set.unmodifiable(members);

  final Set<String> members;
  final expenses = <String, Expense>{};
  final _net = <(String, String), int>{}; // (user, currency) -> net; positive = is owed money
  final _owes = <(String, String, String), int>{}; // (debtor, creditor, currency) -> amount, before simplification
  var _nextId = 1;

  void _checkMember(String user) {
    if (!members.contains(user)) throw ArgumentError('$user is not in the group');
  }

  int net(String user, String currency) => _net[(user, currency)] ?? 0;

  /// Positive: [a] is owed money by [b]; negative: [a] owes [b].
  int between(String a, String b, String currency) => (_owes[(b, a, currency)] ?? 0) - (_owes[(a, b, currency)] ?? 0);

  void _add<K>(Map<K, int> map, K key, int delta) {
    final v = (map[key] ?? 0) + delta;
    if (v == 0) {
      map.remove(key);
    } else {
      map[key] = v;
    }
  }

  void _apply(Expense e, int sign) {
    _add(_net, (e.paidBy, e.currency), sign * e.amount);
    for (final MapEntry(key: user, value: owed) in e.shares.entries) {
      _add(_net, (user, e.currency), -sign * owed);
      if (user != e.paidBy && owed != 0) _add(_owes, (user, e.paidBy, e.currency), sign * owed);
    }
  }

  Expense addExpense({
    required String paidBy,
    required int amount,
    required List<String> participants,
    required SplitStrategy split,
    String currency = 'USD',
    String description = '',
  }) {
    _checkMember(paidBy);
    participants.forEach(_checkMember);
    if (amount <= 0) throw ArgumentError('amount must be positive');
    final e = Expense('e${_nextId++}', paidBy, amount, currency, split.split(amount, participants), description);
    expenses[e.id] = e;
    _apply(e, 1);
    return e;
  }

  /// Replaces an expense's amount and split. [expectedVersion] guards against concurrent edits.
  Expense editExpense(
    String id, {
    required int expectedVersion,
    required int amount,
    required List<String> participants,
    required SplitStrategy split,
  }) {
    final old = expenses[id]!;
    if (old.deleted || old.version != expectedVersion) throw StaleVersionException();
    final shares = split.split(amount, participants); // validate before changing anything
    _apply(old, -1);
    final updated = Expense(id, old.paidBy, amount, old.currency, shares, old.description)..version = old.version + 1;
    expenses[id] = updated;
    _apply(updated, 1);
    return updated;
  }

  void deleteExpense(String id, {required int expectedVersion}) {
    final e = expenses[id]!;
    if (e.deleted || e.version != expectedVersion) throw StaleVersionException();
    _apply(e, -1);
    e
      ..deleted = true
      ..version += 1;
  }

  void settleUp(String from, String to, int amount, {String currency = 'USD'}) {
    _checkMember(from);
    _checkMember(to);
    _add(_net, (from, currency), amount);
    _add(_net, (to, currency), -amount);
    _add(_owes, (from, to, currency), -amount);
  }

  /// Greedy: repeatedly pay from the largest debtor to the largest creditor. At most n - 1 transfers.
  List<Transfer> simplify(String currency) {
    final balances = {for (final m in members) m: net(m, currency)}..removeWhere((_, v) => v == 0);
    final transfers = <Transfer>[];
    while (balances.isNotEmpty) {
      String pick(bool creditor) => balances.keys.reduce((a, b) {
        final va = balances[a]!, vb = balances[b]!;
        if (va == vb) return a.compareTo(b) <= 0 ? a : b; // deterministic ties
        return creditor == (va > vb) ? a : b;
      });
      final creditor = pick(true), debtor = pick(false);
      final amount = min(balances[creditor]!, -balances[debtor]!);
      transfers.add(Transfer(debtor, creditor, amount));
      for (final (user, delta) in [(creditor, -amount), (debtor, amount)]) {
        final v = balances[user]! + delta;
        if (v == 0) {
          balances.remove(user);
        } else {
          balances[user] = v;
        }
      }
    }
    return transfers;
  }

  int totalNet(String currency) => members.fold(0, (sum, m) => sum + net(m, currency));
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void expectThrows<T extends Object>(void Function() f) {
  try {
    f();
  } on T {
    print('ok: threw $T');
    return;
  }
  throw StateError('expected $T');
}

void main() {
  const abc = ['alice', 'bob', 'carol'];

  // Splits always sum to the amount; leftover cents go to the largest remainders, ties in order.
  check(const EqualSplit().split(10000, abc), {'alice': 3334, 'bob': 3333, 'carol': 3333});
  check(const PercentSplit({'alice': 5000, 'bob': 3000, 'carol': 2000}).split(999, abc), {
    'alice': 499,
    'bob': 300,
    'carol': 200,
  });
  check(const ShareSplit({'alice': 1, 'bob': 2, 'carol': 3}).split(600, abc), {'alice': 100, 'bob': 200, 'carol': 300});
  check(const ExactSplit({'alice': 700, 'carol': 300}).split(1000, abc), {'alice': 700, 'bob': 0, 'carol': 300});
  expectThrows<SplitException>(() => const ExactSplit({'alice': 700}).split(1000, abc));
  expectThrows<SplitException>(() => const PercentSplit({'alice': 5000, 'bob': 4000}).split(1000, abc));
  final rng = Random(5);
  for (var i = 0; i < 1000; i++) {
    final amount = rng.nextInt(100000) + 1;
    final shares = {for (final p in abc) p: rng.nextInt(10) + 1};
    final out = ShareSplit(shares).split(amount, abc);
    if (out.values.fold(0, (a, b) => a + b) != amount) throw StateError('split does not sum');
  }

  // A trip: alice pays dinner (90, split by 3); bob pays a taxi (60, split alice/bob).
  final g = Group([...abc, 'dave']);
  final dinner = g.addExpense(paidBy: 'alice', amount: 9000, participants: abc, split: const EqualSplit());
  final taxi = g.addExpense(paidBy: 'bob', amount: 6000, participants: ['alice', 'bob'], split: const EqualSplit());
  check([for (final m in abc) g.net(m, 'USD')], [3000, 0, -3000]);
  check([g.between('alice', 'bob', 'USD'), g.between('alice', 'carol', 'USD')], [0, 3000]);
  check(g.simplify('USD'), [const Transfer('carol', 'alice', 3000)]);

  // Edit with the right version; a stale edit is rejected.
  g.editExpense(dinner.id, expectedVersion: 1, amount: 12000, participants: abc, split: const EqualSplit());
  expectThrows<StaleVersionException>(
    () => g.editExpense(dinner.id, expectedVersion: 1, amount: 1, participants: abc, split: const EqualSplit()),
  );
  check([for (final m in abc) g.net(m, 'USD')], [5000, -1000, -4000]);
  check(g.simplify('USD'), '[carol->alice:4000, bob->alice:1000]');

  // Delete, settle up, invariants.
  g.deleteExpense(taxi.id, expectedVersion: 1);
  check([for (final m in abc) g.net(m, 'USD')], [8000, -4000, -4000]);
  g.settleUp('carol', 'alice', 4000);
  check([g.net('carol', 'USD'), g.between('alice', 'carol', 'USD'), g.totalNet('USD')], [0, 0, 0]);

  // Currencies never mix.
  g.addExpense(paidBy: 'dave', amount: 5000, participants: ['dave', 'bob'], split: const EqualSplit(), currency: 'EUR');
  check([g.net('bob', 'USD'), g.net('bob', 'EUR'), g.simplify('EUR')], [-4000, -2500, '[bob->dave:2500]']);

  // Simplification removes intermediaries: dave paid for erin, erin paid for frank.
  final chain = Group(['dave', 'erin', 'frank']);
  chain
    ..addExpense(paidBy: 'dave', amount: 1000, participants: ['erin'], split: const ExactSplit({'erin': 1000}))
    ..addExpense(paidBy: 'erin', amount: 1000, participants: ['frank'], split: const ExactSplit({'frank': 1000}));
  check([chain.between('erin', 'dave', 'USD'), chain.between('frank', 'erin', 'USD')], [-1000, -1000]);
  check(chain.simplify('USD'), '[frank->dave:1000]');

  expectThrows<ArgumentError>(
    () => g.addExpense(paidBy: 'mallory', amount: 100, participants: abc, split: const EqualSplit()),
  );

  // Random groups: at most n - 1 transfers, and applying them zeroes every balance.
  for (var trial = 0; trial < 200; trial++) {
    final people = ['p0', 'p1', 'p2', 'p3', 'p4', 'p5'];
    final group = Group(people);
    for (var k = 0; k < 8; k++) {
      final participants = people.where((_) => rng.nextBool()).toList();
      if (participants.isEmpty) continue;
      group.addExpense(
        paidBy: people[rng.nextInt(6)],
        amount: rng.nextInt(20000) + 1,
        participants: participants,
        split: const EqualSplit(),
      );
    }
    final plan = group.simplify('USD');
    if (plan.length > people.length - 1) throw StateError('too many transfers');
    for (final t in plan) {
      group.settleUp(t.from, t.to, t.amount);
    }
    if (people.any((p) => group.net(p, 'USD') != 0)) throw StateError('not settled');
  }
  print('ok: 200 random groups settle with at most n - 1 transfers');
}
```

## 5. Walkthrough

- 100.00 split three ways is 10,000 cents: 3,333 each with 1 cent left over, which goes to the first participant because all remainders tie: 3334, 3333, 3333.
- 9.99 at 50/30/20%: exact values 499.5, 299.7, 199.8. Floors sum to 997; the 2 leftover cents go to the largest fractional parts (0.8 and 0.7): 499, 300, 200.
- The trip: alice is owed 90 - 30 - 30 = 30, bob paid 60 and owes 30 + 30 = 0 net, carol owes 30. Pairwise, alice and bob owe each other 30, which cancels. Simplified: carol pays alice 30.
- After editing dinner to 120 (40 each): alice +50, bob -10, carol -40. The greedy plan settles the largest debtor first: carol pays 40, then bob pays 10.
- In the chain, erin owes dave and frank owes erin; the net balances are dave +10, erin 0, frank -10, so a single transfer replaces two.
- 200 random groups confirm the `n - 1` bound and that executing the plan zeroes all balances.

## 6. Concurrency

- All writes for a group touch the same balance rows: process them in one database transaction per expense (sharded by group ID), or with a per-group lock in memory.
- Edits and deletes use optimistic concurrency on `version` (`UPDATE expenses SET ..., version = version + 1 WHERE id = ? AND version = ?`); the loser reloads.
- Reads of balances can use the cached table; `simplify` runs on a consistent snapshot of net balances.

## 7. Extensibility

| Change | Where |
|---|---|
| Multiple payers per expense | `paid: Map<String, int>` on `Expense`; `_apply` credits each payer. |
| Itemized receipts | `ItemizedSplit`: each item has its own participants; shares are summed. |
| Currency conversion at settle-up | A conversion entry: debit in one currency, credit in another at a recorded rate. |
| Exact minimum transfers for small groups | Search over zero-sum subsets (exponential, fine for ~12 people). |
| Recurring expenses | A scheduler creates `addExpense` calls (see 19). |

## 8. Common mistakes in LLD rounds

- `double` money and `amount / n` splits that do not sum back.
- A giant `if (splitType == ...)` in the service instead of strategies.
- Storing only net balances (edits cannot be undone precisely).
- Claiming greedy simplification is optimal.
- Forgetting validation: percentages not summing to 100, exact amounts not summing to the total, non-members.

See [HLD.md](HLD.md) for storage, sharding, edits history and notifications.
