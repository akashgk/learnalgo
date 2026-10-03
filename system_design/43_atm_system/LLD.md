# ATM System: Low-Level Design

## 1. Scope for the LLD round

- **State machine:** idle -> card inserted -> authenticated -> (operations) -> card ejected -> idle; operations in the wrong state are rejected.
- **PIN attempts:** three wrong PINs retain the card.
- **Bank interface:** PIN verification, balance, **idempotent debit by transaction ID**, **reversal**, daily withdrawal limit, insufficient funds.
- **Cash dispenser** with cassettes of limited notes: find the combination with the fewest notes (bounded change-making; greedy fails with limited counts). Check feasibility **before** contacting the bank.
- **Dispense failure after an approved debit** triggers a reversal with the same transaction ID.
- An **audit journal**.

Out of scope: PIN encryption, network messages, deposits (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `AtmState` | `idle`, `cardInserted`, `authenticated`. |
| `Card` | Card number and account. |
| `Bank` (interface), `FakeBank` | Issuer-side checks; debits and reversals keyed by transaction ID. |
| `BankResult` (sealed) | `Approved` or `Declined(reason)`. |
| `CashDispenser` | Cassettes, `plan(amount)` via DP, `dispense(plan)`, simulated jams. |
| `Atm` | The state machine and the withdrawal flow; journal. |

```text
Atm(state) --verifyPin/balance/debit/reverse--> Bank (interface)
   |  withdraw: plan = dispenser.plan(amount)? -> debit(txnId) -> dispense(plan) -> ok
   |                                                    \-> jam -> reverse(txnId)
   +--uses--> CashDispenser (denomination -> count)
```

## 3. Design decisions and why

- **Explicit states with guarded operations** (State pattern in spirit): each method checks the state, so "withdraw without a card" cannot happen.
- **Plan the notes before debiting:** if the ATM cannot pay out the amount, the customer is never charged.
- **Transaction ID per withdrawal,** used for the debit and any reversal: retries and reversals are idempotent at the bank.
- **DP for notes:** with limited cassettes, greedy (largest note first) can fail even when a combination exists (60 with one 50 and three 20s); dynamic programming finds the fewest-notes combination or proves none exists.
- **The bank enforces limits and balances** (the ATM is untrusted hardware in the field).

## 4. The code

```dart
// ---------- Bank ----------

class Card {
  const Card(this.number, this.account);
  final String number;
  final String account;
}

sealed class BankResult {}

class Approved extends BankResult {}

class Declined extends BankResult {
  Declined(this.reason);
  final String reason;
}

abstract interface class Bank {
  bool verifyPin(Card card, String pin);
  int balance(String account);
  BankResult debit(String txnId, String account, int amount, {required int day});
  void reverse(String txnId);
}

class FakeBank implements Bank {
  FakeBank({this.dailyLimit = 1000});
  final int dailyLimit;
  final balances = <String, int>{};
  final pins = <String, String>{}; // card -> PIN (an HSM-verified hash in reality)
  final _debits = <String, (String, int, int)>{}; // txnId -> (account, amount, day)
  final _reversed = <String>{};
  final _withdrawnToday = <(String, int), int>{};
  var debitCalls = 0;

  @override
  bool verifyPin(Card card, String pin) => pins[card.number] == pin;

  @override
  int balance(String account) => balances[account]!;

  @override
  BankResult debit(String txnId, String account, int amount, {required int day}) {
    debitCalls++;
    if (_debits.containsKey(txnId)) return Approved(); // retry of the same transaction
    final today = _withdrawnToday[(account, day)] ?? 0;
    if (today + amount > dailyLimit) return Declined('daily limit exceeded');
    if (balances[account]! < amount) return Declined('insufficient funds');
    balances[account] = balances[account]! - amount;
    _withdrawnToday[(account, day)] = today + amount;
    _debits[txnId] = (account, amount, day);
    return Approved();
  }

  @override
  void reverse(String txnId) {
    final d = _debits[txnId];
    if (d == null || !_reversed.add(txnId)) return; // unknown or already reversed: idempotent
    balances[d.$1] = balances[d.$1]! + d.$2;
    _withdrawnToday[(d.$1, d.$3)] = _withdrawnToday[(d.$1, d.$3)]! - d.$2;
  }
}

// ---------- Cash ----------

class DispenseFailure implements Exception {}

class CashDispenser {
  CashDispenser(Map<int, int> cassettes) : cassettes = Map.of(cassettes);
  final Map<int, int> cassettes; // denomination -> notes available
  var jamNext = false;

  /// Fewest notes that make exactly [amount] with the notes available, or null.
  Map<int, int>? plan(int amount) {
    if (amount <= 0) return null;
    // best[a] = (notes, choice per denomination) for amount a, built denomination by denomination.
    var best = <int, (int, Map<int, int>)>{0: (0, {})};
    for (final MapEntry(key: d, value: count) in cassettes.entries) {
      final next = <int, (int, Map<int, int>)>{};
      best.forEach((a, v) {
        for (var k = 0; k <= count && a + k * d <= amount; k++) {
          final candidate = (v.$1 + k, {...v.$2, if (k > 0) d: k});
          final existing = next[a + k * d];
          if (existing == null || candidate.$1 < existing.$1) next[a + k * d] = candidate;
        }
      });
      best = next;
    }
    return best[amount]?.$2;
  }

  void dispense(Map<int, int> plan) {
    if (jamNext) {
      jamNext = false;
      throw DispenseFailure();
    }
    plan.forEach((d, k) => cassettes[d] = cassettes[d]! - k);
  }

  int get total => cassettes.entries.fold(0, (s, e) => s + e.key * e.value);
}

// ---------- ATM ----------

enum AtmState { idle, cardInserted, authenticated }

class Atm {
  Atm(this.id, this.bank, this.dispenser, {this.maxPinAttempts = 3});
  final String id;
  final Bank bank;
  final CashDispenser dispenser;
  final int maxPinAttempts;
  var state = AtmState.idle;
  Card? _card;
  var _attempts = 0;
  var _txn = 0;
  final retainedCards = <String>[];
  final journal = <String>[];

  void _require(AtmState s) {
    if (state != s) throw StateError('operation not allowed in state ${state.name}');
  }

  void insertCard(Card card) {
    _require(AtmState.idle);
    _card = card;
    _attempts = 0;
    state = AtmState.cardInserted;
  }

  bool enterPin(String pin) {
    _require(AtmState.cardInserted);
    if (bank.verifyPin(_card!, pin)) {
      state = AtmState.authenticated;
      return true;
    }
    if (++_attempts >= maxPinAttempts) {
      retainedCards.add(_card!.number);
      journal.add('card ${_card!.number} retained');
      _reset();
    }
    return false;
  }

  int balance() {
    _require(AtmState.authenticated);
    return bank.balance(_card!.account);
  }

  String withdraw(int amount, {int day = 0}) {
    _require(AtmState.authenticated);
    final notes = dispenser.plan(amount);
    if (notes == null) return 'cannot dispense $amount with available notes';
    final txnId = '$id-${++_txn}';
    final result = bank.debit(txnId, _card!.account, amount, day: day);
    if (result is Declined) {
      journal.add('$txnId declined: ${result.reason}');
      return 'declined: ${result.reason}';
    }
    try {
      dispenser.dispense(notes);
      journal.add('$txnId dispensed $amount as $notes');
      return 'dispensed $notes';
    } on DispenseFailure {
      bank.reverse(txnId); // same transaction ID: the bank releases the debit exactly once
      journal.add('$txnId dispense failed, reversed');
      return 'dispense failed, not charged';
    }
  }

  void ejectCard() {
    if (state == AtmState.idle) return;
    _reset();
  }

  void _reset() {
    _card = null;
    state = AtmState.idle;
  }
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
  final bank = FakeBank(dailyLimit: 300)
    ..balances['acc1'] = 500
    ..pins['card1'] = '1234';
  const card = Card('card1', 'acc1');
  final dispenser = CashDispenser({50: 1, 20: 20});
  final atm = Atm('atm7', bank, dispenser);

  // State guards.
  expectThrows<StateError>(() => atm.withdraw(20));

  // Three wrong PINs retain the card.
  atm.insertCard(card);
  check([atm.enterPin('0000'), atm.enterPin('1111'), atm.enterPin('2222')], [false, false, false]);
  check([atm.state, atm.retainedCards], [AtmState.idle, '[card1]']);

  // Authenticated session.
  atm
    ..insertCard(card)
    ..enterPin('1234');
  check(atm.balance(), 500);

  // Bounded notes: greedy would take the 50 and get stuck at 10; DP pays 60 as 3 x 20.
  check(dispenser.plan(60), {20: 3});
  check(dispenser.plan(70), {50: 1, 20: 1});
  check(atm.withdraw(60), 'dispensed {20: 3}');
  check(
    [atm.balance(), dispenser.cassettes],
    [
      440,
      {50: 1, 20: 17},
    ],
  );

  // An amount the ATM cannot pay is refused before the bank is contacted.
  final callsBefore = bank.debitCalls;
  check([atm.withdraw(30), bank.debitCalls - callsBefore], ['cannot dispense 30 with available notes', 0]);

  // Daily limit (300): 60 already withdrawn today.
  check(atm.withdraw(260), 'declined: daily limit exceeded'); // 60 + 260 > 300
  check(atm.withdraw(110), 'dispensed {50: 1, 20: 3}');

  // Jam after approval: reversal with the same transaction ID; the customer is not charged.
  dispenser.jamNext = true;
  final before = atm.balance();
  check(atm.withdraw(40, day: 1), 'dispense failed, not charged');
  check([atm.balance(), dispenser.cassettes[20]], [before, 14]);
  check(atm.journal.last, 'atm7-4 dispense failed, reversed');

  // Idempotency at the bank: a repeated debit or reversal of one transaction has no extra effect.
  check(bank.debit('atm7-1', 'acc1', 60, day: 0) is Approved, true);
  bank
    ..reverse('atm7-4')
    ..reverse('atm7-4');
  check(atm.balance(), before);

  // Insufficient funds on another account.
  bank
    ..balances['acc2'] = 30
    ..pins['card2'] = '9999';
  atm
    ..ejectCard()
    ..insertCard(const Card('card2', 'acc2'))
    ..enterPin('9999');
  check(atm.withdraw(40), 'declined: insufficient funds');
}
```

## 5. Walkthrough

- Withdrawing before inserting a card throws. Three wrong PINs retain the card and return to idle.
- With one 50 and twenty 20s, 60 is paid as three 20s (the largest-first approach would take the 50 and fail). 70 uses the 50 and one 20.
- 30 cannot be formed from 50s and 20s, so the bank is never called.
- Daily limit 300: after 60 today, a 260 request (total 320) is declined by the bank; 110 (total 170) is paid as one 50 and three 20s.
- A jam after approval (next day, so the limit resets) sends a reversal with transaction `atm7-4`; balance and cassettes are unchanged.
- Repeating a debit or reversal with an existing transaction ID changes nothing.
- A second account with 30 cannot withdraw 40.

## 6. Concurrency

- One customer session per ATM at a time, enforced by the state machine; the ATM is single-threaded.
- At the bank, the debit (check balance and limit, subtract, record the transaction ID) is one database transaction with a unique key on the transaction ID; concurrent withdrawals from two ATMs on the same account serialize on the account row.
- Reversals are idempotent updates keyed by transaction ID.

## 7. Extensibility

| Change | Where |
|---|---|
| Deposits | A new operation and a `NoteAcceptor` device; bank credit with a hold. |
| Other banks' cards | `Bank` implemented by a network client routing to the issuer. |
| Receipts | A printer device invoked after each operation. |
| Out-of-service mode | A state entered when cash is low or a device faults; rejects new cards. |
| Fewest-notes vs keep-small-notes policy | Change the DP objective (e.g. prefer large notes to preserve small ones). |

## 8. Common mistakes in LLD rounds

- One `Atm` class with a big `if/else` on a string state.
- Debiting before checking whether the cash can be dispensed.
- Generating a new transaction ID for the reversal.
- Greedy note selection.

See [HLD.md](HLD.md) for the network, message flows and security.
