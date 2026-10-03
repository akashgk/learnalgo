# E-Commerce Checkout: Low-Level Design

## 1. Scope for the LLD round

- **Cart** with quantities; **pricing**: subtotal from catalog prices, percentage coupon, tax in basis points, integer cents with explicit rounding.
- **Inventory service**: all-or-nothing **reservation** of several SKUs with an expiry, **commit**, **release**, and an expiry sweep. Idempotent by order ID.
- **Payment** and **shipping** services (fakes) with idempotent operations and controllable failures.
- **Checkout saga orchestrator**: reserve stock -> charge -> create shipment -> confirm. On failure, run **compensations** in reverse (refund, release). Every step outcome is written to a **saga log**, so a crashed checkout can **resume** without repeating completed steps.
- **Idempotency key** for the checkout request itself.

Out of scope: real persistence, events/outbox, partial shipments (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Cart`, `priceCart` | Items and the price breakdown. |
| `InventoryService` | Stock counters, reservations (SKU quantities + expiry + committed flag). |
| `PaymentService`, `ShippingService` | External-service stand-ins; idempotent by order ID. |
| `Order`, `OrderStatus` | The order and its lifecycle. |
| `SagaLog` | Completed steps and compensations per order (the durable record a restarted orchestrator reads). |
| `CheckoutService` | Creates orders idempotently; runs and resumes sagas; compensates. |

```text
CheckoutService --writes--> SagaLog (orderId -> [reserve, pay, ship, confirm, compensate:...])
      | step 1 reserve  --> InventoryService     compensation: release
      | step 2 pay      --> PaymentService       compensation: refund
      | step 3 ship     --> ShippingService      (last real step; its failure triggers the compensations above)
      | step 4 confirm  --> commit reservation, order CONFIRMED
```

## 3. Design decisions and why

- **Orchestrated saga** with an explicit step list: the flow is readable in one place and the failure handling is uniform.
- **Reserve before charging:** a customer is never charged for stock that does not exist; an out-of-stock checkout fails before any payment.
- **Every step and compensation is idempotent by order ID**, because the orchestrator may repeat a call after a crash (it cannot know whether the last call took effect).
- **The saga log is consulted before each step:** completed steps are skipped on resume. This is what makes recovery safe.
- **Reservations expire:** abandoned checkouts do not hold stock forever; the commit at the end makes the reservation permanent.
- **Prices in cents; tax computed with integer math** and rounding half up, so totals are reproducible.

## 4. The code

```dart
// ---------- Cart and pricing ----------

class Cart {
  final items = <String, int>{};
  void add(String sku, int qty) => items[sku] = (items[sku] ?? 0) + qty;
}

({int subtotal, int discount, int tax, int total}) priceCart(
  Cart cart,
  Map<String, int> prices, {
  int couponPercent = 0,
  int taxBasisPoints = 800,
}) {
  final subtotal = cart.items.entries.fold(0, (s, e) => s + prices[e.key]! * e.value);
  final discount = subtotal * couponPercent ~/ 100;
  final taxable = subtotal - discount;
  final tax = (taxable * taxBasisPoints + 5000) ~/ 10000;
  return (subtotal: subtotal, discount: discount, tax: tax, total: taxable + tax);
}

// ---------- Downstream services ----------

class FakeClock {
  int now = 0;
}

class InventoryService {
  InventoryService(this.clock, Map<String, int> stock) : available = Map.of(stock);
  final FakeClock clock;
  final Map<String, int> available;
  final _reservations = <String, (Map<String, int>, int, bool)>{}; // orderId -> (items, expiresAt, committed)

  /// All or nothing. Idempotent: reserving again for the same order returns the first answer.
  bool reserve(String orderId, Map<String, int> items, {int ttlSec = 900}) {
    if (_reservations.containsKey(orderId)) return true;
    if (items.entries.any((e) => (available[e.key] ?? 0) < e.value)) return false;
    items.forEach((sku, qty) => available[sku] = available[sku]! - qty);
    _reservations[orderId] = (Map.of(items), clock.now + ttlSec, false);
    return true;
  }

  void commit(String orderId) {
    final r = _reservations[orderId];
    if (r != null) _reservations[orderId] = (r.$1, r.$2, true);
  }

  void release(String orderId) {
    final r = _reservations[orderId];
    if (r == null || r.$3) return; // unknown or already sold
    r.$1.forEach((sku, qty) => available[sku] = available[sku]! + qty);
    _reservations.remove(orderId);
  }

  int expire() {
    final expired = [
      for (final e in _reservations.entries)
        if (!e.value.$3 && e.value.$2 <= clock.now) e.key,
    ];
    expired.forEach(release);
    return expired.length;
  }
}

class PaymentService {
  final charges = <String, int>{};
  final refunds = <String>{};
  final declinedTokens = {'tok_declined'};
  var calls = 0;

  bool charge(String orderId, String token, int amount) {
    calls++;
    if (charges.containsKey(orderId)) return true; // idempotent by order ID
    if (declinedTokens.contains(token)) return false;
    charges[orderId] = amount;
    return true;
  }

  void refund(String orderId) {
    if (charges.containsKey(orderId)) refunds.add(orderId); // a set: refunding twice is a no-op
  }
}

class ShippingService {
  final shipments = <String, String>{};
  final unreachable = {'Nowhere'};

  bool create(String orderId, String address) {
    if (shipments.containsKey(orderId)) return true;
    if (unreachable.contains(address)) return false;
    shipments[orderId] = address;
    return true;
  }
}

// ---------- Orders and the saga ----------

enum OrderStatus { pending, reserved, paid, confirmed, cancelled, failed }

class Order {
  Order(this.id, this.items, this.total, this.token, this.address);
  final String id;
  final Map<String, int> items;
  final int total;
  final String token;
  final String address;
  OrderStatus status = OrderStatus.pending;
  String? reason;
}

class SagaLog {
  final _entries = <String, List<String>>{};
  List<String> of(String orderId) => _entries.putIfAbsent(orderId, () => []);
  bool done(String orderId, String step) => of(orderId).contains(step);
  void record(String orderId, String step) => of(orderId).add(step);
}

class SimulatedCrash implements Exception {}

class CheckoutService {
  CheckoutService({required this.inventory, required this.payments, required this.shipping, required this.prices});
  final InventoryService inventory;
  final PaymentService payments;
  final ShippingService shipping;
  final Map<String, int> prices;
  final log = SagaLog();
  final orders = <String, Order>{};
  final _byKey = <String, Order>{};
  var _nextId = 1;
  String? crashAfterStep; // test hook

  Order checkout(
    String idempotencyKey,
    Cart cart, {
    required String token,
    required String address,
    int couponPercent = 0,
  }) {
    final existing = _byKey[idempotencyKey];
    if (existing != null) return existing;
    final price = priceCart(cart, prices, couponPercent: couponPercent);
    final order = Order('o${_nextId++}', Map.of(cart.items), price.total, token, address);
    orders[order.id] = order;
    _byKey[idempotencyKey] = order;
    _run(order);
    return order;
  }

  /// Called by a recovery job for orders whose saga did not finish.
  void resume(String orderId) => _run(orders[orderId]!);

  void _step(Order o, String name, bool Function() action, OrderStatus onSuccess) {
    if (log.done(o.id, name)) return; // completed before a crash: skip
    if (!action()) throw _StepFailed(name);
    log.record(o.id, name);
    o.status = onSuccess;
    if (crashAfterStep == name) {
      crashAfterStep = null;
      throw SimulatedCrash();
    }
  }

  void _run(Order o) {
    if (o.status == OrderStatus.confirmed || o.status == OrderStatus.cancelled || o.status == OrderStatus.failed)
      return;
    try {
      _step(o, 'reserve', () => inventory.reserve(o.id, o.items), OrderStatus.reserved);
      _step(o, 'pay', () => payments.charge(o.id, o.token, o.total), OrderStatus.paid);
      _step(o, 'ship', () => shipping.create(o.id, o.address), OrderStatus.paid);
      _step(o, 'confirm', () {
        inventory.commit(o.id);
        return true;
      }, OrderStatus.confirmed);
    } on _StepFailed catch (f) {
      _compensate(o, f.step);
    }
  }

  void _compensate(Order o, String failedStep) {
    o.reason = '$failedStep failed';
    if (log.done(o.id, 'pay')) {
      payments.refund(o.id);
      log.record(o.id, 'compensate:refund');
    }
    if (log.done(o.id, 'reserve')) {
      inventory.release(o.id);
      log.record(o.id, 'compensate:release');
    }
    o.status = failedStep == 'reserve' ? OrderStatus.failed : OrderStatus.cancelled;
  }
}

class _StepFailed implements Exception {
  _StepFailed(this.step);
  final String step;
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  const prices = {'A': 1000, 'B': 2500, 'C': 300};
  final clock = FakeClock();
  final inventory = InventoryService(clock, {'A': 5, 'B': 2, 'C': 1});
  final payments = PaymentService();
  final shipping = ShippingService();
  final service = CheckoutService(inventory: inventory, payments: payments, shipping: shipping, prices: prices);
  Cart cart(Map<String, int> items) {
    final c = Cart();
    items.forEach(c.add);
    return c;
  }

  // Pricing: 4500 subtotal, 10% coupon, 8% tax.
  check(priceCart(cart({'A': 2, 'B': 1}), prices, couponPercent: 10), (
    subtotal: 4500,
    discount: 450,
    tax: 324,
    total: 4374,
  ));

  // Happy path.
  final o1 = service.checkout('k1', cart({'A': 2, 'B': 1}), token: 'tok_ok', address: 'Berlin', couponPercent: 10);
  check(
    [o1.status, o1.total, inventory.available, payments.charges[o1.id], shipping.shipments[o1.id]],
    [
      OrderStatus.confirmed,
      4374,
      {'A': 3, 'B': 1, 'C': 1},
      4374,
      'Berlin',
    ],
  );
  check(service.log.of(o1.id), ['reserve', 'pay', 'ship', 'confirm']);
  check(identical(service.checkout('k1', cart({'A': 2, 'B': 1}), token: 'tok_ok', address: 'Berlin'), o1), true);
  check(payments.charges.length, 1);

  // Payment declined: stock released, nothing charged.
  final o2 = service.checkout('k2', cart({'A': 1}), token: 'tok_declined', address: 'Berlin');
  check(
    [o2.status, o2.reason, inventory.available['A'], service.log.of(o2.id)],
    [
      OrderStatus.cancelled,
      'pay failed',
      3,
      ['reserve', 'compensate:release'],
    ],
  );

  // Shipping fails after payment: refund and release, in reverse order.
  final o3 = service.checkout('k3', cart({'B': 1}), token: 'tok_ok', address: 'Nowhere');
  check(
    [o3.status, payments.refunds.contains(o3.id), inventory.available['B'], service.log.of(o3.id)],
    [
      OrderStatus.cancelled,
      true,
      1,
      ['reserve', 'pay', 'compensate:refund', 'compensate:release'],
    ],
  );

  // Out of stock: fails before any payment attempt.
  final callsBefore = payments.calls;
  final o4 = service.checkout('k4', cart({'B': 5}), token: 'tok_ok', address: 'Berlin');
  check([o4.status, payments.calls - callsBefore, service.log.of(o4.id)], [OrderStatus.failed, 0, '[]']);

  // Crash after charging; recovery resumes from the saga log without charging twice.
  service.crashAfterStep = 'pay';
  Order? crashed;
  try {
    service.checkout('k5', cart({'A': 1}), token: 'tok_ok', address: 'Paris');
  } on SimulatedCrash {
    crashed = service.orders.values.last;
  }
  check(
    [crashed!.status, service.log.of(crashed.id)],
    [
      OrderStatus.paid,
      ['reserve', 'pay'],
    ],
  );
  final calls = payments.calls;
  service.resume(crashed.id);
  check([crashed.status, payments.calls - calls, payments.charges.length], [OrderStatus.confirmed, 0, 3]);

  // Abandoned reservations expire and return stock.
  inventory.reserve('abandoned', {'A': 2});
  check(inventory.available['A'], 0);
  clock.now = 901;
  check([inventory.expire(), inventory.available['A']], [1, 2]);

  // Two buyers race for the last unit of C: exactly one order is confirmed.
  final x = service.checkout('k6', cart({'C': 1}), token: 'tok_ok', address: 'Rome');
  final y = service.checkout('k7', cart({'C': 1}), token: 'tok_ok', address: 'Oslo');
  check([x.status, y.status, inventory.available['C']], [OrderStatus.confirmed, OrderStatus.failed, 0]);
}
```

## 5. Walkthrough

- Pricing: subtotal 2 x 1000 + 2500 = 4500; 10% off is 450; 8% tax on 4050 is 324; total 4374.
- The happy path reserves A x 2 and B x 1, charges 4374, creates a shipment, commits the reservation, and logs four steps. Retrying with `k1` returns the same order; only one charge exists.
- A declined card fails the `pay` step: the reservation is released (A back to 3), the order is cancelled, and the log shows the compensation.
- An unreachable address fails `ship` after payment: compensations run in reverse (refund, then release).
- B x 5 is more than the stock (1 left), so reservation fails and the payment service is never called. The order is `failed` (nothing to undo) rather than `cancelled`.
- The simulated crash happens right after `pay` was logged. `resume` skips `reserve` and `pay` (already in the log), creates the shipment and confirms. No extra payment call is made.
- An abandoned reservation of 2 A's expires after 900 s and the stock returns.
- The last unit of C goes to the first checkout; the second fails at reservation.

## 6. Concurrency

- Inventory reservation is one atomic conditional update per SKU in one transaction (or a Lua script in Redis for flash sales), so two checkouts cannot both take the last unit.
- The saga log and order status are updated in the same local transaction as each step's outcome is recorded; a recovery job picks up orders stuck in non-final states (with a lease, so two recovery workers do not run the same saga).
- Downstream calls are idempotent by order ID, so a step retried after a timeout is harmless.

## 7. Extensibility

| Change | Where |
|---|---|
| Authorize, then capture after shipping | Split `pay` into `authorize` (compensation: void) and `capture` after `ship`. |
| Loyalty points | A new step with its compensation, inserted into the step list. |
| Choreography instead of orchestration | Each service listens to events and emits the next; harder to see the whole flow. |
| Multiple warehouses | Reservation picks a warehouse per SKU; shipping per warehouse. |
| Outbox events | Record `OrderConfirmed` in the same transaction as the final status. |

## 8. Common mistakes in LLD rounds

- Charging first, reserving later.
- Compensations that are not idempotent (double refunds on retry).
- No persisted saga state (a crash leaves orders half done forever).
- Partial reservations (some SKUs reserved, others not).
- Floating-point prices and tax.

See [HLD.md](HLD.md) for the service architecture, flash sales and the order lifecycle.
