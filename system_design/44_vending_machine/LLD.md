# Vending Machine: Low-Level Design

## 1. Scope for the LLD round

- **State pattern** with one class per state: `Idle`, `HasMoney`, `OutOfService`. The machine delegates every action to its current state object.
- **Coins:** only accepted denominations (5, 10, 25, 100 cents); inserted coins are held in **escrow** until a sale completes, so a cancellation returns exactly the coins inserted.
- **Selection:** sold out, insufficient money (with the amount still needed), and "cannot make change" are reported without taking the money.
- **Change-making with limited coins:** fewest coins via dynamic programming over the tubes (escrowed coins included); greedy fails with limited counts (30 from one 25 and three 10s).
- **Jams:** if the product does not drop, the customer is refunded.
- **Exact-change-only** indicator and **restock**.

Out of scope: card payments, telemetry (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Slot` | Product, price, count. |
| `Outcome` | Message, dispensed product, coins returned. |
| `VendingState` (abstract) | Default behavior for each action (reject); subclasses override what is valid. |
| `IdleState`, `HasMoneyState`, `OutOfServiceState` | Per-state rules. |
| `makeChange` | Bounded fewest-coins change. |
| `VendingMachine` | Context: slots, coin tubes, escrow, current state, jam simulation, admin operations. |

```text
VendingMachine (context) --delegates--> VendingState
                                         ^         ^             ^
                                    IdleState  HasMoneyState  OutOfServiceState
Idle --insertCoin--> HasMoney --select (ok)--> Idle      HasMoney --cancel--> Idle
any --setOutOfService--> OutOfService --setInService--> Idle
```

## 3. Design decisions and why

- **State classes instead of a switch over an enum:** each state's rules live together; adding a state (e.g. `Maintenance`) does not touch the others (Open/Closed).
- **Escrow:** coins are not mixed into the tubes until the sale commits, which makes refunds exact and keeps accounting simple.
- **Check everything before taking the money:** stock, price, and change are verified first; the state only changes when the sale can complete.
- **DP change-making over bounded coin counts:** correct for any coin set and inventory; greedy is only safe with unlimited coins of a canonical system.
- **Integer cents** for all money.

## 4. The code

```dart
class Slot {
  Slot(this.product, this.price, this.count);
  final String product;
  final int price; // cents
  int count;
}

class Outcome {
  const Outcome(this.message, {this.product, this.coins = const []});
  final String message;
  final String? product;
  final List<int> coins; // returned to the customer
  @override
  String toString() => '$message${product == null ? '' : ' [$product]'}${coins.isEmpty ? '' : ' coins=$coins'}';
}

/// Fewest coins summing to [amount] using at most the available count of each denomination; null if impossible.
List<int>? makeChange(int amount, Map<int, int> available) {
  if (amount == 0) return [];
  var best = <int, List<int>>{0: []};
  for (final MapEntry(key: coin, value: count) in available.entries) {
    final next = <int, List<int>>{};
    best.forEach((sum, coins) {
      for (var k = 0; k <= count && sum + k * coin <= amount; k++) {
        final candidate = [...coins, for (var i = 0; i < k; i++) coin];
        final existing = next[sum + k * coin];
        if (existing == null || candidate.length < existing.length) next[sum + k * coin] = candidate;
      }
    });
    best = next;
  }
  return (best[amount]?..sort((a, b) => b.compareTo(a)));
}

abstract class VendingState {
  String get name;
  Outcome insertCoin(VendingMachine m, int coin) => throw StateError('cannot insert coins while $name');
  Outcome select(VendingMachine m, String slot) => throw StateError('cannot select while $name');
  Outcome cancel(VendingMachine m) => throw StateError('cannot cancel while $name');
}

class IdleState extends VendingState {
  @override
  String get name => 'idle';

  @override
  Outcome insertCoin(VendingMachine m, int coin) {
    if (!VendingMachine.accepted.contains(coin)) return Outcome('rejected coin', coins: [coin]);
    m.escrow.add(coin);
    m.state = m.hasMoney;
    return Outcome('balance ${m.balance}');
  }

  @override
  Outcome select(VendingMachine m, String slot) => const Outcome('insert money first');

  @override
  Outcome cancel(VendingMachine m) => const Outcome('nothing to return');
}

class HasMoneyState extends VendingState {
  @override
  String get name => 'has money';

  @override
  Outcome insertCoin(VendingMachine m, int coin) {
    if (!VendingMachine.accepted.contains(coin)) return Outcome('rejected coin', coins: [coin]);
    m.escrow.add(coin);
    return Outcome('balance ${m.balance}');
  }

  @override
  Outcome select(VendingMachine m, String slotId) {
    final slot = m.slots[slotId];
    if (slot == null) return const Outcome('unknown slot');
    if (slot.count == 0) return Outcome('${slot.product} sold out');
    if (m.balance < slot.price) return Outcome('insert ${slot.price - m.balance} more');

    // Change may use the tubes plus the coins just inserted.
    final pool = Map.of(m.tubes);
    for (final c in m.escrow) {
      pool[c] = (pool[c] ?? 0) + 1;
    }
    final change = makeChange(m.balance - slot.price, pool);
    if (change == null) return const Outcome('cannot make change: use exact amount or cancel');

    if (m.jamNext) {
      m.jamNext = false;
      return _refund(m, 'product stuck: refunded');
    }
    m.tubes = pool; // commit: escrow joins the tubes
    for (final c in change) {
      m.tubes[c] = m.tubes[c]! - 1;
    }
    m.escrow.clear();
    slot.count--;
    m.state = m.idle;
    return Outcome('enjoy', product: slot.product, coins: change);
  }

  @override
  Outcome cancel(VendingMachine m) => _refund(m, 'cancelled');

  Outcome _refund(VendingMachine m, String message) {
    final coins = List.of(m.escrow); // exactly the coins inserted
    m.escrow.clear();
    m.state = m.idle;
    return Outcome(message, coins: coins);
  }
}

class OutOfServiceState extends VendingState {
  @override
  String get name => 'out of service';
}

class VendingMachine {
  VendingMachine(this.slots, this.tubes);
  static const accepted = {5, 10, 25, 100};

  final Map<String, Slot> slots;
  Map<int, int> tubes; // coins available for change
  final escrow = <int>[];
  final idle = IdleState(), hasMoney = HasMoneyState(), outOfService = OutOfServiceState();
  late VendingState state = idle;
  var jamNext = false;

  int get balance => escrow.fold(0, (a, b) => a + b);
  bool get exactChangeOnly => makeChange(5, tubes) == null || makeChange(10, tubes) == null;

  Outcome insertCoin(int coin) => state.insertCoin(this, coin);
  Outcome select(String slot) => state.select(this, slot);
  Outcome cancel() => state.cancel(this);

  void restock(String slot, int count) => slots[slot]!.count += count;

  /// Maintenance: refunds any escrow and stops accepting customers.
  List<int> setOutOfService() {
    final coins = List.of(escrow);
    escrow.clear();
    state = outOfService;
    return coins;
  }

  void setInService() => state = idle;
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
  // Change-making with limited coins: greedy would take 25 and then fail on 5.
  check(makeChange(30, {25: 1, 10: 3}), [10, 10, 10]);
  check(makeChange(35, {25: 2, 10: 2, 5: 2}), [25, 10]);
  check(makeChange(15, {25: 3, 10: 1}), null);

  final m = VendingMachine({'A1': Slot('chips', 65, 2), 'B1': Slot('soda', 125, 0)}, {25: 2, 10: 2, 5: 2});

  // Happy path with change.
  check(m.select('A1'), 'insert money first');
  check(m.insertCoin(100), 'balance 100');
  check(m.select('A1'), 'enjoy [chips] coins=[25, 10]');
  check(
    [m.state.name, m.tubes],
    [
      'idle',
      {25: 1, 10: 1, 5: 2, 100: 1},
    ],
  );

  // Insufficient money, invalid coins, and topping up.
  m.insertCoin(25);
  check([m.select('A1'), m.insertCoin(1)], ['insert 40 more', 'rejected coin coins=[1]']);
  m
    ..insertCoin(25)
    ..insertCoin(25);
  check(m.select('A1'), 'enjoy [chips] coins=[10]');

  // Sold out keeps the money; cancel returns exactly the inserted coins.
  m
    ..insertCoin(100)
    ..insertCoin(25);
  check(m.select('B1'), 'soda sold out');
  check(m.select('A1'), 'chips sold out');
  check(m.cancel(), 'cancelled coins=[100, 25]');

  // Restock; change that cannot be made is refused before vending.
  m.restock('A1', 5);
  final poor = VendingMachine({'A1': Slot('chips', 65, 5)}, {25: 1});
  poor.insertCoin(100);
  check(poor.select('A1'), 'cannot make change: use exact amount or cancel');
  check([poor.slots['A1']!.count, poor.balance, poor.exactChangeOnly], [5, 100, true]);
  check(poor.cancel(), 'cancelled coins=[100]');
  poor
    ..insertCoin(25)
    ..insertCoin(25)
    ..insertCoin(10)
    ..insertCoin(5);
  check(poor.select('A1'), 'enjoy [chips]'); // exact amount needs no change

  // Jam: refund, no stock or coins consumed.
  m.jamNext = true;
  m.insertCoin(100);
  check([m.select('A1'), m.slots['A1']!.count], ['product stuck: refunded coins=[100]', 5]);

  // Out of service.
  m.insertCoin(10);
  check(m.setOutOfService(), [10]);
  expectThrows<StateError>(() => m.insertCoin(25));
  m.setInService();
  check(m.insertCoin(25), 'balance 25');
}
```

## 5. Walkthrough

- `makeChange(30, {25: 1, 10: 3})` returns three 10s; 15 from 25s and one 10 is impossible.
- 100 cents for 65-cent chips: change 35 = 25 + 10 from the tubes; the 100 joins the tubes.
- With 25 inserted, chips need 40 more; a 1-cent coin is rejected and handed back; two more 25s make 75 and the change is 10.
- After two sales the chips slot is empty: both selections report sold out and keep the money; cancel returns the 100 and the 25 actually inserted.
- A machine holding only one 25 cannot return 35, so the sale is refused before anything changes; it is in exact-change-only mode. Paying exactly 65 works.
- A jam refunds the 100 and leaves the stock at 5.
- Out of service refunds the escrow and rejects coins until put back in service.

## 6. Concurrency

- A physical machine processes one customer at a time; the controller handles hardware events (coin, button, drop sensor) on one event loop, so the state machine needs no locks.
- Hardware events can arrive "out of order" (a button press during coin validation): the state object decides whether an event is valid now.
- Telemetry and remote configuration run on a separate task and apply changes only in the idle state.

## 7. Extensibility

| Change | Where |
|---|---|
| Card payments | A `HasCardAuthorization` state; capture after the drop sensor confirms. |
| Notes | Add denominations and a note escrow; change policy may avoid giving notes. |
| Maintenance mode | Another `VendingState` subclass allowing restock and cash collection. |
| Promotions | Price function per slot (time of day, combos). |

## 8. Common mistakes in LLD rounds

- A single class with `if (state == ...)` everywhere.
- Taking the money before checking stock and change.
- Greedy change with limited coins.
- Returning different coins than inserted on cancel (fine in practice, but it complicates accounting and confuses users when it changes the coin mix).

See [HLD.md](HLD.md) for the connected-fleet design.
