# Stock Exchange / Order Matching Engine: Low-Level Design

## 1. Scope for the LLD round

- An **order book** for one symbol: bids sorted high to low, asks low to high; each price level is a FIFO queue (**price-time priority**).
- Order types: **limit** (match what crosses, rest the remainder), **market** (match at any price, never rest), **IOC** (immediate-or-cancel: match what crosses, cancel the remainder).
- **Partial fills** and multi-level sweeps; trades execute at the **resting** order's price.
- **Cancel** by order ID; best bid/ask and depth for market data.
- A **matching engine** that journals every command with a sequence number and can **replay** the journal into an identical book (event sourcing).

Out of scope: risk checks, gateways, market data transport (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Side`, `OrderType` | Enums. |
| `Order` | ID, side, type, limit price (integer ticks), quantity, remaining. |
| `Trade` | Buy order ID, sell order ID, price, quantity. |
| `OrderBook` | Price levels per side, ID index, `submit`, `cancel`, `bestBid`, `bestAsk`, `depth`. |
| `Command` | A journaled input: new order or cancel. |
| `MatchingEngine` | Sequences commands into the journal, applies them, records trades; `replay`. |

```text
MatchingEngine --journal[seq]--> Command (new | cancel)
      |
      +--applies to--> OrderBook: bids SplayTreeMap<price, Queue<Order>> (descending)
                                  asks SplayTreeMap<price, Queue<Order>> (ascending)
                                  byId: Map<orderId, Order>   --> trades
```

## 3. Design decisions and why

- **Sorted map of price levels + FIFO queue per level:** best price is the first key (O(log levels)); within a level, the earliest order fills first.
- **Prices as integer ticks:** no floating-point comparisons in matching.
- **Trades at the resting order's price:** the order that was in the book set the price; the aggressor gets any price improvement.
- **Market and IOC orders never rest;** their unfilled remainder is canceled, which is reported.
- **Single-threaded, deterministic `submit`:** no clocks, randomness or I/O inside matching, so replaying the journal reproduces the exact book and trades.
- **ID index for cancels:** finding the order is O(1); removing it from its level queue is O(level size) here (production uses an intrusive doubly linked list for O(1)).

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

enum Side { buy, sell }

enum OrderType { limit, market, ioc }

class Order {
  Order(this.id, this.side, this.type, this.quantity, [this.price]) : remaining = quantity {
    if (quantity <= 0) throw ArgumentError('quantity must be positive');
    if (type != OrderType.market && price == null) throw ArgumentError('limit and IOC orders need a price');
  }
  final String id;
  final Side side;
  final OrderType type;
  final int quantity;
  final int? price; // ticks
  int remaining;
}

class Trade {
  const Trade(this.buyId, this.sellId, this.price, this.quantity);
  final String buyId;
  final String sellId;
  final int price;
  final int quantity;
  @override
  String toString() => '$buyId/$sellId $quantity@$price';
}

class DuplicateOrderException implements Exception {}

class OrderBook {
  final bids = SplayTreeMap<int, Queue<Order>>((a, b) => b.compareTo(a)); // best (highest) first
  final asks = SplayTreeMap<int, Queue<Order>>(); // best (lowest) first
  final _resting = <String, Order>{};
  final canceledRemainders = <String, int>{};

  int? get bestBid => bids.isEmpty ? null : bids.firstKey();
  int? get bestAsk => asks.isEmpty ? null : asks.firstKey();
  bool isResting(String id) => _resting.containsKey(id);

  bool _crosses(Order o, int bookPrice) =>
      o.type == OrderType.market || (o.side == Side.buy ? bookPrice <= o.price! : bookPrice >= o.price!);

  List<Trade> submit(Order o) {
    if (_resting.containsKey(o.id)) throw DuplicateOrderException();
    final trades = <Trade>[];
    final opposite = o.side == Side.buy ? asks : bids;
    while (o.remaining > 0 && opposite.isNotEmpty) {
      final price = opposite.firstKey()!;
      if (!_crosses(o, price)) break;
      final level = opposite[price]!;
      final resting = level.first;
      final qty = min(o.remaining, resting.remaining);
      trades.add(o.side == Side.buy ? Trade(o.id, resting.id, price, qty) : Trade(resting.id, o.id, price, qty));
      o.remaining -= qty;
      resting.remaining -= qty;
      if (resting.remaining == 0) {
        level.removeFirst();
        _resting.remove(resting.id);
        if (level.isEmpty) opposite.remove(price);
      }
    }
    if (o.remaining > 0) {
      if (o.type == OrderType.limit) {
        (o.side == Side.buy ? bids : asks).putIfAbsent(o.price!, Queue.new).add(o);
        _resting[o.id] = o;
      } else {
        canceledRemainders[o.id] = o.remaining; // market / IOC never rest
      }
    }
    return trades;
  }

  bool cancel(String id) {
    final o = _resting.remove(id);
    if (o == null) return false;
    final side = o.side == Side.buy ? bids : asks;
    final level = side[o.price!]!..remove(o);
    if (level.isEmpty) side.remove(o.price!);
    return true;
  }

  /// (price, total quantity) for the best [levels] levels.
  List<(int, int)> depth(Side side, int levels) => [
    for (final e in (side == Side.buy ? bids : asks).entries.take(levels))
      (e.key, e.value.fold(0, (s, o) => s + o.remaining)),
  ];

  String snapshot() => 'bids ${depth(Side.buy, 1 << 20)} asks ${depth(Side.sell, 1 << 20)}';
}

// ---------- Engine with journal ----------

class Command {
  const Command.newOrder(this.id, this.side, this.type, this.quantity, [this.price]) : isCancel = false;
  const Command.cancel(this.id) : isCancel = true, side = Side.buy, type = OrderType.limit, quantity = 0, price = null;
  final String id;
  final bool isCancel;
  final Side side;
  final OrderType type;
  final int quantity;
  final int? price;
}

class MatchingEngine {
  final book = OrderBook();
  final journal = <(int, Command)>[];
  final trades = <Trade>[];

  List<Trade> process(Command c) {
    journal.add((journal.length + 1, c)); // sequenced and persisted before being applied
    if (c.isCancel) {
      book.cancel(c.id);
      return const [];
    }
    final t = book.submit(Order(c.id, c.side, c.type, c.quantity, c.price));
    trades.addAll(t);
    return t;
  }

  static MatchingEngine replay(List<(int, Command)> journal) {
    final engine = MatchingEngine();
    for (final (_, c) in journal) {
      engine.process(c);
    }
    return engine;
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
  final e = MatchingEngine();
  e
    ..process(const Command.newOrder('S1', Side.sell, OrderType.limit, 10, 101))
    ..process(const Command.newOrder('S2', Side.sell, OrderType.limit, 5, 101)) // same price, later
    ..process(const Command.newOrder('S3', Side.sell, OrderType.limit, 8, 102))
    ..process(const Command.newOrder('B1', Side.buy, OrderType.limit, 7, 99));
  check([e.book.bestBid, e.book.bestAsk], [99, 101]);
  check(e.book.depth(Side.sell, 2), '[(101, 15), (102, 8)]');

  // Price-time priority and partial fills.
  check(e.process(const Command.newOrder('B2', Side.buy, OrderType.limit, 12, 101)), '[B2/S1 10@101, B2/S2 2@101]');
  check(e.book.depth(Side.sell, 2), '[(101, 3), (102, 8)]');

  // A market order sweeps levels at the resting prices.
  check(e.process(const Command.newOrder('B3', Side.buy, OrderType.market, 6)), '[B3/S2 3@101, B3/S3 3@102]');

  // A non-crossing limit order rests; the aggressor gets the resting (better) price.
  check(e.process(const Command.newOrder('B4', Side.buy, OrderType.limit, 20, 100)), '[]');
  check(e.process(const Command.newOrder('S4', Side.sell, OrderType.limit, 5, 98)), '[B4/S4 5@100]');

  // IOC: fills what it can across levels, the rest is canceled, nothing rests.
  check(e.process(const Command.newOrder('S5', Side.sell, OrderType.ioc, 30, 99)), '[B4/S5 15@100, B1/S5 7@99]');
  check([e.book.canceledRemainders['S5'], e.book.isResting('S5'), e.book.bestBid], [8, false, null]);

  // Cancels.
  e.process(const Command.cancel('S3'));
  check([e.book.bestAsk, e.book.cancel('S3')], [null, false]);
  expectThrows<ArgumentError>(() => Order('X', Side.buy, OrderType.limit, 0, 100));
  expectThrows<ArgumentError>(() => Order('Y', Side.buy, OrderType.limit, 5));

  // Randomized: the book is never crossed, and replaying the journal reproduces book and trades exactly.
  final rng = Random(11);
  final live = MatchingEngine();
  final ids = <String>[];
  for (var i = 0; i < 3000; i++) {
    if (ids.isNotEmpty && rng.nextInt(5) == 0) {
      live.process(Command.cancel(ids[rng.nextInt(ids.length)]));
    } else {
      final id = 'o$i';
      ids.add(id);
      final side = rng.nextBool() ? Side.buy : Side.sell;
      final type = [OrderType.limit, OrderType.limit, OrderType.limit, OrderType.ioc, OrderType.market][rng.nextInt(5)];
      live.process(
        Command.newOrder(id, side, type, 1 + rng.nextInt(20), type == OrderType.market ? null : 95 + rng.nextInt(11)),
      );
    }
    final bid = live.book.bestBid, ask = live.book.bestAsk;
    if (bid != null && ask != null && bid >= ask) throw StateError('crossed book at command $i');
  }
  final replayed = MatchingEngine.replay(live.journal);
  check(replayed.book.snapshot() == live.book.snapshot() && '${replayed.trades}' == '${live.trades}', true);
  check(live.trades.length > 500, true);
}
```

## 5. Walkthrough

- S1 and S2 are both at 101; S1 arrived first, so B2 (12 @ 101) fills 10 from S1 then 2 from S2. S2 keeps 3.
- The market buy for 6 takes S2's last 3 at 101, then 3 from S3 at 102.
- B4 (buy 20 @ 100) does not cross the best ask (102) and rests. S4 (sell 5 @ 98) crosses it and trades at 100, the resting price: the seller gets a better price than asked.
- The IOC sell for 30 @ 99 takes 15 from B4 at 100 and 7 from B1 at 99; its remaining 8 are canceled instead of resting, leaving no bids.
- Cancelling S3 empties the ask side; cancelling it again returns false.
- 3,000 random commands (limit, IOC, market, cancels) never leave a crossed book, and replaying the journal reproduces the same book and the same trade list.

## 6. Concurrency

- One thread owns each book; commands arrive through a single-producer queue from the sequencer (an LMAX-style ring buffer). No locks inside matching.
- Parallelism comes from symbols: different books on different cores.
- Outputs (trades, book updates) are written to an outbound ring buffer consumed by market data and execution-report threads, so I/O never blocks matching.

## 7. Extensibility

| Change | Where |
|---|---|
| Fill-or-kill | Check available crossing quantity before matching; reject if insufficient. |
| Modify order | Cancel + new (loses time priority) or in-place quantity reduction (keeps it). |
| Stop orders | A separate trigger book watched on each trade price. |
| Self-trade prevention | Compare account IDs before creating a trade. |
| Snapshots | Serialize the book every N commands; replay only the journal after it. |

## 8. Common mistakes in LLD rounds

- One sorted list of all orders (no price levels), making best-price lookup and cancels slow.
- Executing at the incoming order's price instead of the resting price.
- Letting market or IOC remainders rest in the book.
- Floating-point prices.
- Nondeterminism (timestamps or randomness) inside matching.

See [HLD.md](HLD.md) for sequencing, replication, risk checks and market data.
