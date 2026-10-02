# Payment System: Low-Level Design

## 1. Scope for the LLD round

- `pay(idempotencyKey, request)`: create a payment for an order and charge it through a PSP. Retried requests with the same key return the same payment; the same key with a different body is rejected; a second payment for the same order is rejected.
- **Payment state machine** with an explicit `unknown` state for timeouts, resolved by querying the PSP or by a webhook.
- **Double-entry ledger**: every transaction sums to zero; transactions are idempotent by ID; balances are derived.
- Fees: the platform keeps a percentage; the rest is owed to the seller.
- **Refunds**, partial and full, never more than what was captured.
- **Webhooks** deduplicated by event ID.

Out of scope: authorization/capture split, payouts, FX, fraud (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Ledger` | Accounts and immutable entries; `post(txId, entries)` enforces zero sum and idempotency; `balance(account)`. |
| `PaymentStatus` | `processing`, `succeeded`, `failed`, `unknown`, `partiallyRefunded`, `refunded`; allowed transitions. |
| `Payment` | Amount (integer minor units) and currency, seller, status, refunded amount, event history. |
| `Psp` (interface) | `charge(paymentId, token, amount)`, `refund(...)`, `query(paymentId)`; our payment ID is its idempotency key. |
| `PspResult` (sealed) | `PspSuccess`, `PspDeclined`, `PspTimeout`. |
| `IdempotencyStore` | Key -> request fingerprint and result. |
| `PaymentService` | Orchestrates: idempotency, state transitions, PSP calls, ledger postings, webhooks, refunds. |

```text
PaymentService --uses--> IdempotencyStore   (key -> fingerprint, paymentId)
      |        --uses--> Psp (interface)    <-- FakePsp (idempotent by paymentId, can time out after charging)
      |        --uses--> Ledger             (transactions of entries summing to zero)
      +--has many--> Payment --status--> PaymentStatus (transition table)
```

## 3. Design decisions and why

- **Integer minor units** everywhere; fee rounding is explicit (`basis points`, rounded half up).
- **Idempotency in three places:** the API key (client retries), our payment ID sent to the PSP (our retries), and webhook event IDs (PSP retries). Each layer is safe to repeat.
- **`unknown` is a state, not an error.** A timeout may hide a successful charge. The service never re-charges with a new key and never marks it failed without asking the PSP.
- **Ledger postings keyed by a deterministic transaction ID** (`charge:<paymentId>`, `refund:<refundKey>`): even if the success path runs twice (query and webhook racing), money moves once.
- **Transition table** in one place; every change goes through `_transition`, which records an event.
- **Refunds reverse the seller's share** (the platform keeps its fee in this policy). The rule is one method, easy to change.

## 4. The code

```dart
// ---------- Ledger ----------

class LedgerEntry {
  const LedgerEntry(this.account, this.amount);
  final String account;
  final int amount; // positive = debit, negative = credit; minor units
}

class UnbalancedTransactionException implements Exception {}

class Ledger {
  final _transactions = <String, List<LedgerEntry>>{};
  final _balances = <String, int>{};

  /// Posts once per [txId]; posting the same ID again is a no-op. Entries must sum to zero.
  bool post(String txId, List<LedgerEntry> entries) {
    if (_transactions.containsKey(txId)) return false;
    if (entries.fold(0, (sum, e) => sum + e.amount) != 0) throw UnbalancedTransactionException();
    _transactions[txId] = List.unmodifiable(entries);
    for (final e in entries) {
      _balances[e.account] = (_balances[e.account] ?? 0) + e.amount;
    }
    return true;
  }

  int balance(String account) => _balances[account] ?? 0;
  int get transactionCount => _transactions.length;
  int get total => _balances.values.fold(0, (a, b) => a + b); // always 0
}

// ---------- PSP ----------

sealed class PspResult {}

class PspSuccess extends PspResult {
  PspSuccess(this.reference);
  final String reference;
}

class PspDeclined extends PspResult {
  PspDeclined(this.reason);
  final String reason;
}

class PspTimeout extends PspResult {}

abstract interface class Psp {
  PspResult charge(String paymentId, String token, int amount);
  PspResult refund(String refundId, String paymentId, int amount);
  PspResult query(String paymentId); // the authoritative outcome of a charge
}

// ---------- Payments ----------

enum PaymentStatus {
  processing,
  succeeded,
  failed,
  unknown,
  partiallyRefunded,
  refunded;

  bool canMoveTo(PaymentStatus to) => switch (this) {
    processing => {succeeded, failed, unknown}.contains(to),
    unknown => {succeeded, failed}.contains(to),
    succeeded || partiallyRefunded => {partiallyRefunded, refunded}.contains(to),
    failed || refunded => false,
  };
}

class PaymentRequest {
  const PaymentRequest({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.token,
    required this.sellerId,
  });
  final String orderId;
  final int amount;
  final String currency;
  final String token;
  final String sellerId;

  String get fingerprint => '$orderId|$amount|$currency|$token|$sellerId';
}

class Payment {
  Payment(this.id, this.request);
  final String id;
  final PaymentRequest request;
  PaymentStatus status = PaymentStatus.processing;
  String? pspReference;
  int refunded = 0;
  final events = <String>[];
}

class IdempotencyMismatchException implements Exception {}

class DuplicateOrderException implements Exception {}

class InvalidTransitionException implements Exception {
  InvalidTransitionException(this.from, this.to);
  final PaymentStatus from;
  final PaymentStatus to;
}

class RefundException implements Exception {
  RefundException(this.message);
  final String message;
}

class IdempotencyStore {
  final _entries = <String, (String, String)>{}; // key -> (fingerprint, result)

  /// The stored result for [key], or null if new. Throws if the key was used for a different request.
  String? lookup(String key, String fingerprint) {
    final e = _entries[key];
    if (e == null) return null;
    if (e.$1 != fingerprint) throw IdempotencyMismatchException();
    return e.$2;
  }

  void save(String key, String fingerprint, String result) => _entries[key] = (fingerprint, result);
}

class PaymentService {
  PaymentService({required this.psp, required this.ledger, this.feeBasisPoints = 1000});

  final Psp psp;
  final Ledger ledger;
  final int feeBasisPoints; // 1000 = 10%
  final payments = <String, Payment>{};
  final _byOrder = <String, String>{};
  final _idempotency = IdempotencyStore();
  final _seenWebhookEvents = <String>{};
  var _nextId = 1;

  int feeFor(int amount) => (amount * feeBasisPoints + 5000) ~/ 10000; // round half up

  Payment pay(String idempotencyKey, PaymentRequest r) {
    final previous = _idempotency.lookup(idempotencyKey, r.fingerprint);
    if (previous != null) return payments[previous]!;
    if (_byOrder.containsKey(r.orderId)) throw DuplicateOrderException();

    final p = Payment('pay_${_nextId++}', r);
    payments[p.id] = p;
    _byOrder[r.orderId] = p.id;
    _idempotency.save(idempotencyKey, r.fingerprint, p.id); // in one DB transaction with the insert
    p.events.add('created');
    _applyChargeResult(p, psp.charge(p.id, r.token, r.amount));
    return p;
  }

  void _applyChargeResult(Payment p, PspResult result) {
    switch (result) {
      case PspSuccess(:final reference):
        _transition(p, PaymentStatus.succeeded);
        p.pspReference = reference;
        final fee = feeFor(p.request.amount);
        ledger.post('charge:${p.id}', [
          LedgerEntry('psp_clearing:${p.request.currency}', p.request.amount),
          LedgerEntry('seller:${p.request.sellerId}:${p.request.currency}', -(p.request.amount - fee)),
          LedgerEntry('platform_fees:${p.request.currency}', -fee),
        ]);
      case PspDeclined(:final reason):
        _transition(p, PaymentStatus.failed);
        p.events.add('declined: $reason');
      case PspTimeout():
        _transition(p, PaymentStatus.unknown); // never assume either outcome
    }
  }

  /// Background job for payments stuck in `unknown`: ask the PSP, using our payment ID.
  void resolveUnknown(String paymentId) {
    final p = payments[paymentId]!;
    if (p.status != PaymentStatus.unknown) return;
    final result = psp.query(paymentId);
    if (result is! PspTimeout) _applyChargeResult(p, result);
  }

  /// PSP webhooks can arrive late, twice, or out of order.
  void onWebhook(String eventId, String paymentId, {required bool succeeded, String reference = ''}) {
    if (!_seenWebhookEvents.add(eventId)) return; // duplicate delivery
    final p = payments[paymentId]!;
    if (p.status != PaymentStatus.unknown && p.status != PaymentStatus.processing) return; // already final
    _applyChargeResult(p, succeeded ? PspSuccess(reference) : PspDeclined('reported by webhook'));
  }

  void refund(String idempotencyKey, String paymentId, int amount) {
    final p = payments[paymentId]!;
    if (_idempotency.lookup(idempotencyKey, '$paymentId|$amount') != null) return; // already done
    if (!p.status.canMoveTo(PaymentStatus.refunded)) throw InvalidTransitionException(p.status, PaymentStatus.refunded);
    if (amount <= 0 || p.refunded + amount > p.request.amount) throw RefundException('exceeds captured amount');

    final result = psp.refund(idempotencyKey, paymentId, amount);
    if (result is! PspSuccess) throw RefundException('psp refund not confirmed; retry with the same key');
    _idempotency.save(idempotencyKey, '$paymentId|$amount', 'ok');
    p.refunded += amount;
    _transition(p, p.refunded == p.request.amount ? PaymentStatus.refunded : PaymentStatus.partiallyRefunded);
    // Policy: the seller returns the refunded amount; the platform keeps its fee.
    ledger.post('refund:$idempotencyKey', [
      LedgerEntry('seller:${p.request.sellerId}:${p.request.currency}', amount),
      LedgerEntry('psp_clearing:${p.request.currency}', -amount),
    ]);
  }

  void _transition(Payment p, PaymentStatus to) {
    if (!p.status.canMoveTo(to)) throw InvalidTransitionException(p.status, to);
    p.events.add('${p.status.name} -> ${to.name}');
    p.status = to;
  }
}

// ---------- Test double ----------

class FakePsp implements Psp {
  final _charged = <String, int>{}; // paymentId -> amount: charging is idempotent by our ID
  final _refunds = <String>{};
  var chargeCalls = 0;
  final declinedTokens = <String>{'tok_declined'};
  final timeoutAfterChargingTokens = <String>{'tok_slow'};

  int get totalCharged => _charged.values.fold(0, (a, b) => a + b);

  @override
  PspResult charge(String paymentId, String token, int amount) {
    chargeCalls++;
    if (declinedTokens.contains(token)) return PspDeclined('card declined');
    _charged.putIfAbsent(paymentId, () => amount);
    if (timeoutAfterChargingTokens.contains(token)) return PspTimeout(); // charged, but the response was lost
    return PspSuccess('psp_$paymentId');
  }

  @override
  PspResult refund(String refundId, String paymentId, int amount) {
    _refunds.add(refundId);
    return PspSuccess('re_$refundId');
  }

  @override
  PspResult query(String paymentId) =>
      _charged.containsKey(paymentId) ? PspSuccess('psp_$paymentId') : PspDeclined('no such charge');
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
  final psp = FakePsp();
  final ledger = Ledger();
  final service = PaymentService(psp: psp, ledger: ledger);
  PaymentRequest req(String order, int amount, [String token = 'tok_ok']) =>
      PaymentRequest(orderId: order, amount: amount, currency: 'USD', token: token, sellerId: 's1');

  // Successful payment: ledger entries sum to zero; the fee is 10% rounded half up.
  final p1 = service.pay('key-1', req('order-1', 4999));
  check([p1.status, service.feeFor(4999)], [PaymentStatus.succeeded, 500]);
  check(
    [ledger.balance('psp_clearing:USD'), ledger.balance('seller:s1:USD'), ledger.balance('platform_fees:USD')],
    [4999, -4499, -500],
  );
  check(ledger.total, 0);

  // Client retry with the same key: same payment, no second charge. Misuse is rejected.
  check(identical(service.pay('key-1', req('order-1', 4999)), p1), true);
  check([psp.chargeCalls, psp.totalCharged], [1, 4999]);
  expectThrows<IdempotencyMismatchException>(() => service.pay('key-1', req('order-1', 5999)));
  expectThrows<DuplicateOrderException>(() => service.pay('key-2', req('order-1', 4999)));

  // Declined: failed, no money moved.
  final p2 = service.pay('key-3', req('order-2', 1000, 'tok_declined'));
  check([p2.status, ledger.transactionCount], [PaymentStatus.failed, 1]);

  // Timeout after the PSP charged: unknown, then resolved by querying. Resolving twice changes nothing.
  final p3 = service.pay('key-4', req('order-3', 2000, 'tok_slow'));
  check([p3.status, ledger.transactionCount], [PaymentStatus.unknown, 1]);
  service.resolveUnknown(p3.id);
  service.resolveUnknown(p3.id);
  check([p3.status, ledger.transactionCount, psp.totalCharged], [PaymentStatus.succeeded, 2, 6999]);

  // Webhooks: duplicates and late events for a final payment are ignored.
  final p4 = service.pay('key-5', req('order-4', 3000, 'tok_slow'));
  service.onWebhook('evt-1', p4.id, succeeded: true, reference: 'psp_x');
  service.onWebhook('evt-1', p4.id, succeeded: true, reference: 'psp_x');
  service.onWebhook('evt-2', p4.id, succeeded: false); // stale, payment already final
  check([p4.status, ledger.transactionCount], [PaymentStatus.succeeded, 3]);

  // Refunds: partial, idempotent, full; never more than captured.
  service.refund('rf-1', p1.id, 1000);
  service.refund('rf-1', p1.id, 1000); // client retry
  check([p1.status, p1.refunded], [PaymentStatus.partiallyRefunded, 1000]);
  expectThrows<RefundException>(() => service.refund('rf-2', p1.id, 4000));
  service.refund('rf-3', p1.id, 3999);
  check([p1.status, ledger.balance('seller:s1:USD')], [PaymentStatus.refunded, -(4499 + 1800 + 2700) + 4999]);
  expectThrows<InvalidTransitionException>(() => service.refund('rf-4', p1.id, 1));
  expectThrows<InvalidTransitionException>(() => service.refund('rf-5', p2.id, 1)); // failed payment
  check(ledger.total, 0);

  // The ledger rejects unbalanced transactions and ignores replays.
  expectThrows<UnbalancedTransactionException>(
    () => ledger.post('bad', [const LedgerEntry('a', 100), const LedgerEntry('b', -99)]),
  );
  check(ledger.post('charge:${p1.id}', const []), false);
  check(p1.events, [
    'created',
    'processing -> succeeded',
    'succeeded -> partiallyRefunded',
    'partiallyRefunded -> refunded',
  ]);
}
```

## 5. Walkthrough

- `$49.99` with a 10% fee: `(4999 x 1000 + 5000) ~/ 10000 = 500`. The ledger posts clearing `+4999`, seller `-4499`, fees `-500`: zero sum.
- The retry with `key-1` returns the stored payment before any PSP call. The same key with a different amount is a client bug and is rejected. A new key for an already paid order is also rejected (`order_id` is unique).
- `tok_slow` makes the fake PSP charge the card but lose the response. The payment becomes `unknown`; `resolveUnknown` queries the PSP by our payment ID, finds the charge, and posts the ledger once (the transaction ID `charge:<id>` makes a second posting a no-op).
- Seller balance after both refunds: the seller was credited 4,499 (p1) + 1,800 (p3) + 2,700 (p4) and debited 4,999 by refunds, so the balance is `-(4499 + 1800 + 2700) + 4999`. The platform keeps its 500 fee under this policy.

## 6. Concurrency

- Idempotency: insert the key row with `in_progress` inside the same transaction as the payment row (unique constraint). A concurrent duplicate request blocks on or fails the unique insert and then returns the stored result.
- State transitions: conditional updates (`UPDATE payments SET status = 'succeeded' WHERE id = ? AND status IN ('processing', 'unknown')`); the loser of a race (webhook vs query job) changes nothing.
- Ledger: the transaction ID is a primary key; entries and the cached balance update commit together. Lock accounts in a fixed order when updating several balances.
- Never hold a database transaction open across the PSP call: record `processing`, commit, call the PSP, then record the outcome.

## 7. Extensibility

| Change | Where |
|---|---|
| Authorize then capture | Add `authorized` and `capturing` states; capture posts the ledger. |
| Second PSP | Another `Psp` adapter; route new payments by health and cost. |
| Chargebacks | A `disputed` state and a ledger transaction debiting the seller. |
| Different fee policy | Replace `feeFor` and the refund posting with a `FeePolicy` strategy. |
| Event publishing | Write an outbox row alongside each transition. |

## 8. Common mistakes in LLD rounds

- `double amount`.
- A `balance` field mutated directly with no entries.
- Treating a PSP timeout as failure and retrying with a fresh key.
- Unconditional status updates (a late "failed" webhook overwriting "succeeded").
- Refund checks that ignore previous partial refunds.

See [HLD.md](HLD.md) for the services, outbox, reconciliation and payouts.
