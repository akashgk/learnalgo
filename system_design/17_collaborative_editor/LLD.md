# Collaborative Editor: Low-Level Design

## 1. Scope for the LLD round

- Plain-text documents edited by several clients at once.
- Operations: `Insert(pos, text)`, `Delete(pos)` (one character), `Noop`.
- **Transform function** `transform(a, b)`: rewrite `a` so it applies after `b`, for every pair of operation types, with a deterministic tie-break for inserts at the same position.
- **Server**: one per document; keeps the revision history, transforms incoming ops against everything committed since the client's base revision, acks the sender, broadcasts to the others.
- **Client**: applies local edits immediately; at most one op **in flight**; later local ops wait in a **buffer**; incoming remote ops are transformed against in-flight and buffered ops.
- A **randomized convergence test** with arbitrary message interleavings.

Out of scope: rich text, persistence, presence, reconnection (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Op` (sealed) | `Insert`, `Delete`, `Noop`, each tagged with the site (client) that made it. |
| `applyOp` | Applies an op to a string. |
| `transform` | The OT inclusion transformation for all op pairs. |
| `Server` | Document, history (index = revision), `receive(op, baseRev)`. |
| `Client` | Local document, last known server revision, in-flight op, buffer, outbox. |
| `Network` | FIFO channels client -> server and server -> client; delivers one message at a time. |

```text
Client --outbox (op, baseRev)--> Server --ack--> sender Client
   ^                                |
   +---------- remote op -----------+--> every other Client
Client state: doc, rev, inflight?, buffer[]        Server state: doc, history[] (revision = length)
```

## 3. Design decisions and why

- **Central ordering:** the server's history is the single total order. Clients never transform against each other directly, only against server-ordered ops. This is the Jupiter / Google Docs model and it only needs the transform property TP1: `apply(apply(s, a), transform(b, a)) == apply(apply(s, b), transform(a, b))`.
- **One op in flight per client.** The server can then transform it against a contiguous range of history, and the client knows exactly which op an ack refers to.
- **Tie-break by site ID** for inserts at the same position, so both sides order the two inserts the same way.
- **Delete vs delete of the same character becomes a `Noop`**: the character is already gone.
- **Ops are immutable values;** transforming creates new ops. Easier to reason about and to test.
- Single-character deletes keep the transform small and correct; range deletes are a straightforward extension (split into ranges) but have more cases.

## 4. The code

```dart
import 'dart:collection';
import 'dart:math';

// ---------- Operations ----------

sealed class Op {
  const Op(this.site);
  final String site;
}

class Insert extends Op {
  const Insert(this.pos, this.text, super.site);
  final int pos;
  final String text;
  @override
  String toString() => 'ins($pos,"$text")';
}

class Delete extends Op {
  const Delete(this.pos, super.site);
  final int pos;
  @override
  String toString() => 'del($pos)';
}

class Noop extends Op {
  const Noop(super.site);
  @override
  String toString() => 'noop';
}

String applyOp(String doc, Op op) => switch (op) {
  Insert(:final pos, :final text) => doc.substring(0, pos) + text + doc.substring(pos),
  Delete(:final pos) => doc.substring(0, pos) + doc.substring(pos + 1),
  Noop() => doc,
};

/// Rewrites [a] so it can be applied after [b]; both were made against the same document.
Op transform(Op a, Op b) => switch ((a, b)) {
  (Noop(), _) || (_, Noop()) => a,
  (Insert x, Insert y) =>
    x.pos < y.pos || (x.pos == y.pos && x.site.compareTo(y.site) < 0)
        ? x
        : Insert(x.pos + y.text.length, x.text, x.site),
  (Insert x, Delete y) => x.pos <= y.pos ? x : Insert(x.pos - 1, x.text, x.site),
  (Delete x, Insert y) => x.pos < y.pos ? x : Delete(x.pos + y.text.length, x.site),
  (Delete x, Delete y) =>
    x.pos < y.pos
        ? x
        : x.pos > y.pos
        ? Delete(x.pos - 1, x.site)
        : Noop(x.site),
};

// ---------- Server ----------

class Server {
  Server(this.doc);
  String doc;
  final history = <Op>[];
  int get revision => history.length;

  /// Transforms [op] (made at [baseRev]) against everything committed since, applies it, returns it.
  Op receive(Op op, int baseRev) {
    var t = op;
    for (final committed in history.sublist(baseRev)) {
      t = transform(t, committed);
    }
    doc = applyOp(doc, t);
    history.add(t);
    return t;
  }
}

// ---------- Client ----------

class Client {
  Client(this.site, this.doc, this.rev);
  final String site;
  String doc;
  int rev; // server revision this client has seen
  Op? inflight;
  final buffer = <Op>[];
  final outbox = Queue<(Op, int)>();

  void insert(int pos, String text) => _local(Insert(pos, text, site));
  void delete(int pos) => _local(Delete(pos, site));

  void _local(Op op) {
    doc = applyOp(doc, op); // optimistic: the user sees it immediately
    if (inflight == null) {
      inflight = op;
      outbox.add((op, rev));
    } else {
      buffer.add(op);
    }
  }

  void onAck() {
    rev++;
    inflight = null;
    if (buffer.isNotEmpty) {
      inflight = buffer.removeAt(0);
      outbox.add((inflight!, rev)); // now based on a state that includes the acked op
    }
  }

  void onRemote(Op op) {
    rev++;
    var remote = op;
    final pending = inflight;
    if (pending != null) {
      inflight = transform(pending, remote);
      remote = transform(remote, pending);
    }
    for (var i = 0; i < buffer.length; i++) {
      final b = buffer[i];
      buffer[i] = transform(b, remote);
      remote = transform(remote, b);
    }
    doc = applyOp(doc, remote);
  }
}

// ---------- Network simulation ----------

class Network {
  Network(this.server, this.clients);
  final Server server;
  final List<Client> clients;
  final _toClient = <String, Queue<Op?>>{}; // null = ack

  Queue<Op?> _queue(Client c) => _toClient.putIfAbsent(c.site, Queue.new);

  /// Deliver the oldest message from [c] to the server.
  bool deliverToServer(Client c) {
    if (c.outbox.isEmpty) return false;
    final (op, baseRev) = c.outbox.removeFirst();
    final committed = server.receive(op, baseRev);
    for (final other in clients) {
      _queue(other).add(identical(other, c) ? null : committed);
    }
    return true;
  }

  /// Deliver the oldest server message to [c].
  bool deliverToClient(Client c) {
    final q = _queue(c);
    if (q.isEmpty) return false;
    final message = q.removeFirst();
    if (message == null) {
      c.onAck();
    } else {
      c.onRemote(message);
    }
    return true;
  }

  void drain() {
    var progress = true;
    while (progress) {
      progress = false;
      for (final c in clients) {
        progress = deliverToServer(c) | deliverToClient(c) | progress;
      }
    }
  }
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

void main() {
  // The classic example: concurrent insert at 0 and delete of "c".
  check(transform(const Delete(2, 'bob'), const Insert(0, 'X', 'alice')), 'del(3)');
  {
    final server = Server('abc');
    final alice = Client('alice', 'abc', 0), bob = Client('bob', 'abc', 0);
    final net = Network(server, [alice, bob]);
    alice.insert(0, 'X');
    bob.delete(2);
    check([alice.doc, bob.doc], ['Xabc', 'ab']); // both see their own edit at once
    net.drain();
    check([server.doc, alice.doc, bob.doc], ['Xab', 'Xab', 'Xab']);
  }

  // Concurrent inserts at the same position: the site ID breaks the tie identically everywhere.
  {
    final server = Server('abc');
    final alice = Client('alice', 'abc', 0), bob = Client('bob', 'abc', 0);
    final net = Network(server, [alice, bob]);
    bob.insert(1, 'B');
    alice.insert(1, 'A');
    net
      ..deliverToServer(bob) // bob's op reaches the server first
      ..drain();
    check([server.doc, alice.doc, bob.doc], ['aABbc', 'aABbc', 'aABbc']);
  }

  // Both delete the same character: one becomes a no-op.
  {
    final server = Server('abc');
    final alice = Client('alice', 'abc', 0), bob = Client('bob', 'abc', 0);
    final net = Network(server, [alice, bob]);
    alice.delete(1);
    bob.delete(1);
    net.drain();
    check([server.doc, alice.doc, bob.doc, server.history], ['ac', 'ac', 'ac', '[del(1), noop]']);
  }

  // TP1 on random pairs: applying a then b' equals applying b then a'.
  final rng = Random(3);
  Op randomOp(String doc, String site) => doc.isNotEmpty && rng.nextBool()
      ? Delete(rng.nextInt(doc.length), site)
      : Insert(rng.nextInt(doc.length + 1), String.fromCharCode(97 + rng.nextInt(3)), site);
  var pairs = 0;
  for (var i = 0; i < 5000; i++) {
    final s = String.fromCharCodes(List.generate(rng.nextInt(5), (_) => 97 + rng.nextInt(3)));
    final a = randomOp(s, 'x'), b = randomOp(s, 'y');
    if (applyOp(applyOp(s, a), transform(b, a)) != applyOp(applyOp(s, b), transform(a, b))) {
      throw StateError('TP1 fails for $s, $a, $b');
    }
    pairs++;
  }
  check(pairs, 5000);

  // Randomized convergence: three clients, random edits, random message delivery order.
  for (var seed = 0; seed < 30; seed++) {
    final r = Random(seed);
    final server = Server('hello');
    final clients = [
      for (final s in ['a', 'b', 'c']) Client(s, 'hello', 0),
    ];
    final net = Network(server, clients);
    for (var step = 0; step < 300; step++) {
      final c = clients[r.nextInt(clients.length)];
      switch (r.nextInt(10)) {
        case < 4:
          if (c.doc.isNotEmpty && r.nextBool()) {
            c.delete(r.nextInt(c.doc.length));
          } else {
            c.insert(r.nextInt(c.doc.length + 1), String.fromCharCode(97 + r.nextInt(26)));
          }
        case < 7:
          net.deliverToServer(c);
        default:
          net.deliverToClient(c);
      }
    }
    net.drain();
    for (final c in clients) {
      if (c.doc != server.doc || c.inflight != null || c.buffer.isNotEmpty) {
        throw StateError('seed $seed: ${c.site} has "${c.doc}", server has "${server.doc}"');
      }
    }
  }
  print('ok: 30 random sessions converged');
}
```

## 5. Walkthrough

- Alice inserts `X` at 0 and Bob deletes position 2 (`c`), both against revision 0. Alice's op reaches the server first (revision 1). Bob's delete arrives with base revision 0, so the server transforms it against `ins(0,"X")`: `del(2)` becomes `del(3)`, which removes `c` from `"Xabc"`. Alice receives `del(3)`; Bob receives Alice's insert, transforms it against his in-flight delete (position 0 is before 2, unchanged) and applies it. Everyone has `"Xab"`.
- Same-position inserts: Bob's `B` is committed first, but `alice < bob`, so Alice's `A` goes before `B` on every replica: `"aABbc"`.
- Both delete `b`: the second delete, transformed against the first, becomes `noop`; the history shows it.
- 5,000 random pairs check TP1 directly; 30 random sessions with 300 steps each (edits, deliveries to server and to clients in random order) all converge with nothing left in flight.

## 6. Concurrency

- The server processes one op at a time per document (a single-threaded actor per document), which defines the total order. Different documents run in parallel on different servers.
- A client's UI thread applies local ops and remote ops on the same thread (the browser event loop), so client state needs no locks.
- Network delivery must be FIFO per connection (WebSocket over TCP guarantees it); reconnection resends the in-flight op with its base revision, and the server deduplicates by (site, client sequence).

## 7. Extensibility

| Change | Where |
|---|---|
| Range deletes | `Delete(pos, length)` with overlap cases in `transform` (split or shrink ranges). |
| Rich text | `Format(start, end, attrs)` ops transformed like a range. |
| Remote cursors | Treat a cursor as a zero-length insert and transform it with every remote op. |
| Undo | Invert the user's own op and transform the inverse against all later ops. |
| Offline / peer-to-peer | Replace OT with a sequence CRDT (characters with unique IDs, tombstones). |

## 8. Common mistakes in LLD rounds

- Applying remote ops without transforming them against unacknowledged local ops.
- Sending several local ops concurrently with the same base revision without transforming them against each other.
- No tie-break for same-position inserts (replicas diverge).
- Forgetting the delete-delete same-position case.
- Testing only one hand-picked interleaving.

See [HLD.md](HLD.md) for document ownership, persistence, presence and the OT vs CRDT discussion.
