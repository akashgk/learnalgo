# Library Management System: Low-Level Design

## 1. Scope for the LLD round

- **Titles vs copies:** `Book` (ISBN, title, author) and `Copy` (barcode, status: available, on loan, on hold shelf).
- **Members** with a maximum number of active loans; borrowing **blocked** when unpaid fines exceed a threshold.
- **Checkout, return, renew** with rules: 14-day loans, at most 2 renewals, no renewal while others wait.
- **Holds:** FIFO queue per title; only allowed when no copy is available; a returned copy goes to the **hold shelf** for the next member with a **pickup deadline**; expired holds pass to the next member.
- **Fines:** per overdue day, capped per item; payment.
- **Search** by title or author; **notifications** as a log.

Out of scope: multiple branches and transfers, e-books (HLD).

## 2. Entities and responsibilities

| Class | Responsibility |
|---|---|
| `Book`, `Copy`, `CopyStatus` | Catalog entry; physical item and its state. |
| `Member` | ID, name, loan limit. |
| `Loan` | Copy, member, due day, renewals. |
| `LibraryException` | Rule violations with a readable message. |
| `Library` | Catalog, circulation rules, hold queues, fines, clock (day number), notifications. |

```text
Library --has many--> Book --has many--> Copy (available | onLoan | onHoldShelf(heldFor, expiresDay))
        --has many--> Member --has many--> Loan (dueDay, renewals)
        --holds: isbn -> Queue<memberId>          --fines: memberId -> cents
```

## 3. Design decisions and why

- **Holds are per title, not per copy:** whichever copy comes back first serves the next person; fair and fast.
- **Copy status as an explicit state** with transitions only through `Library` methods; a copy on the hold shelf can only go to its holder.
- **Rules in one place** (`Library`), named and parameterized (loan days, fine rate, caps), so policy changes do not ripple through the model.
- **Day numbers** as the clock: deterministic tests; real systems use dates in the library's time zone.
- **Integer cents for fines.**

## 4. The code

```dart
import 'dart:collection';

class Book {
  const Book(this.isbn, this.title, this.author);
  final String isbn;
  final String title;
  final String author;
}

enum CopyStatus { available, onLoan, onHoldShelf }

class Copy {
  Copy(this.barcode, this.isbn);
  final String barcode;
  final String isbn;
  CopyStatus status = CopyStatus.available;
  String? heldFor;
  int? holdExpiresDay;
}

class Member {
  const Member(this.id, this.name, {this.maxLoans = 5});
  final String id;
  final String name;
  final int maxLoans;
}

class Loan {
  Loan(this.copy, this.memberId, this.dueDay);
  final Copy copy;
  final String memberId;
  int dueDay;
  int renewals = 0;
}

class LibraryException implements Exception {
  LibraryException(this.message);
  final String message;
  @override
  String toString() => message;
}

class Library {
  Library({
    this.loanDays = 14,
    this.maxRenewals = 2,
    this.finePerDay = 25,
    this.maxFinePerItem = 500,
    this.blockAtFines = 1000,
    this.pickupDays = 7,
  });

  final int loanDays, maxRenewals, finePerDay, maxFinePerItem, blockAtFines, pickupDays;
  var today = 0;
  final books = <String, Book>{};
  final copies = <String, Copy>{};
  final members = <String, Member>{};
  final _loans = <String, Loan>{}; // barcode -> active loan
  final _holds = <String, Queue<String>>{}; // isbn -> member IDs
  final fines = <String, int>{};
  final notifications = <String>[];

  void addBook(Book b, List<String> barcodes) {
    books[b.isbn] = b;
    for (final code in barcodes) {
      copies[code] = Copy(code, b.isbn);
    }
  }

  void addMember(Member m) => members[m.id] = m;

  List<String> search(String query) {
    final q = query.toLowerCase();
    return [
      for (final b in books.values)
        if (b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q)) b.title,
    ];
  }

  int activeLoans(String memberId) => _loans.values.where((l) => l.memberId == memberId).length;
  Loan? loanOf(String barcode) => _loans[barcode];
  List<String> holdQueue(String isbn) => List.of(_holds[isbn] ?? const <String>[]);

  Loan checkout(String memberId, String barcode) {
    final member = members[memberId] ?? (throw LibraryException('unknown member'));
    final copy = copies[barcode] ?? (throw LibraryException('unknown copy'));
    if ((fines[memberId] ?? 0) >= blockAtFines) throw LibraryException('blocked: unpaid fines');
    if (activeLoans(memberId) >= member.maxLoans) throw LibraryException('loan limit reached');
    switch (copy.status) {
      case CopyStatus.onLoan:
        throw LibraryException('copy already on loan');
      case CopyStatus.onHoldShelf when copy.heldFor != memberId:
        throw LibraryException('copy is on hold for someone else');
      case CopyStatus.onHoldShelf || CopyStatus.available:
        break;
    }
    copy
      ..status = CopyStatus.onLoan
      ..heldFor = null
      ..holdExpiresDay = null;
    return _loans[barcode] = Loan(copy, memberId, today + loanDays);
  }

  /// Returns the fine charged for this item.
  int returnCopy(String barcode) {
    final loan = _loans.remove(barcode) ?? (throw LibraryException('copy is not on loan'));
    final late = today - loan.dueDay;
    final fine = late > 0 ? (late * finePerDay).clamp(0, maxFinePerItem) : 0;
    if (fine > 0) fines[loan.memberId] = (fines[loan.memberId] ?? 0) + fine;
    _routeToNextHolder(loan.copy);
    return fine;
  }

  void _routeToNextHolder(Copy copy) {
    final queue = _holds[copy.isbn];
    if (queue == null || queue.isEmpty) {
      copy
        ..status = CopyStatus.available
        ..heldFor = null
        ..holdExpiresDay = null;
      return;
    }
    final next = queue.removeFirst();
    copy
      ..status = CopyStatus.onHoldShelf
      ..heldFor = next
      ..holdExpiresDay = today + pickupDays;
    notifications.add('$next: "${books[copy.isbn]!.title}" ready until day ${copy.holdExpiresDay}');
  }

  void renew(String memberId, String barcode) {
    final loan = _loans[barcode];
    if (loan == null || loan.memberId != memberId) throw LibraryException('not your loan');
    if (_holds[loan.copy.isbn]?.isNotEmpty ?? false) throw LibraryException('others are waiting');
    if (loan.renewals >= maxRenewals) throw LibraryException('renewal limit reached');
    loan
      ..renewals += 1
      ..dueDay += loanDays;
  }

  void placeHold(String memberId, String isbn) {
    final mine = copies.values.where((c) => c.isbn == isbn);
    if (mine.any((c) => c.status == CopyStatus.available)) throw LibraryException('a copy is available now');
    if (mine.any((c) => _loans[c.barcode]?.memberId == memberId)) throw LibraryException('you already have it');
    final queue = _holds.putIfAbsent(isbn, Queue.new);
    if (queue.contains(memberId) || mine.any((c) => c.heldFor == memberId)) throw LibraryException('already on hold');
    queue.add(memberId);
  }

  /// Daily job: uncollected holds pass to the next member (or back to the shelf).
  void expireHolds() {
    for (final c in copies.values.where((c) => c.status == CopyStatus.onHoldShelf && c.holdExpiresDay! < today)) {
      notifications.add('${c.heldFor}: hold on "${books[c.isbn]!.title}" expired');
      _routeToNextHolder(c);
    }
  }

  void payFine(String memberId, int amount) => fines[memberId] = (fines[memberId] ?? 0) - amount;
}

// ---------- Self-checks ----------

void check(Object? actual, Object? expected) {
  if ('$actual' != '$expected') throw StateError('expected $expected, got $actual');
  print('ok: $actual');
}

String error(void Function() f) {
  try {
    f();
    return 'ok';
  } on LibraryException catch (e) {
    return e.message;
  }
}

void main() {
  final lib = Library()
    ..addBook(const Book('978-1', 'Designing Data-Intensive Applications', 'Martin Kleppmann'), ['D1', 'D2'])
    ..addBook(const Book('978-2', 'The Pragmatic Programmer', 'Hunt and Thomas'), ['P1'])
    ..addMember(const Member('alice', 'Alice', maxLoans: 2))
    ..addMember(const Member('bob', 'Bob'))
    ..addMember(const Member('carol', 'Carol'))
    ..addMember(const Member('dave', 'Dave'));

  check(lib.search('kleppmann'), ['Designing Data-Intensive Applications']);

  // Checkout rules and limits.
  lib
    ..checkout('alice', 'D1')
    ..checkout('alice', 'P1');
  check(
    [error(() => lib.checkout('alice', 'D2')), error(() => lib.checkout('bob', 'D1'))],
    ['loan limit reached', 'copy already on loan'],
  );

  // Holds only when nothing is on the shelf.
  check(error(() => lib.placeHold('carol', '978-1')), 'a copy is available now');
  lib.checkout('bob', 'D2');
  lib
    ..placeHold('carol', '978-1')
    ..placeHold('dave', '978-1');
  check(
    [lib.holdQueue('978-1'), error(() => lib.placeHold('carol', '978-1')), error(() => lib.placeHold('bob', '978-1'))],
    [
      ['carol', 'dave'],
      'already on hold',
      'you already have it',
    ],
  );

  // Renewal: allowed when nobody waits, blocked when others do, and limited.
  lib.renew('alice', 'P1');
  lib.renew('alice', 'P1');
  check(
    [error(() => lib.renew('alice', 'P1')), error(() => lib.renew('alice', 'D1'))],
    ['renewal limit reached', 'others are waiting'],
  );

  // Overdue return: 3 days late -> 75 cents; the copy goes to Carol's hold shelf, not back to the stacks.
  lib.today = 17;
  check(lib.returnCopy('D1'), 75);
  check(
    [lib.copies['D1']!.status, lib.copies['D1']!.heldFor, lib.notifications.last],
    [CopyStatus.onHoldShelf, 'carol', 'carol: "Designing Data-Intensive Applications" ready until day 24'],
  );
  check(error(() => lib.checkout('dave', 'D1')), 'copy is on hold for someone else');
  lib.checkout('carol', 'D1');

  // Dave's turn comes with the next copy; he never picks it up, so it returns to the shelf.
  lib.today = 18;
  lib.returnCopy('D2');
  lib.today = 26;
  lib.expireHolds();
  check(
    [lib.copies['D2']!.status, lib.notifications.last],
    [CopyStatus.available, 'dave: hold on "Designing Data-Intensive Applications" expired'],
  );

  // Fines: capped per item; members above the threshold are blocked until they pay.
  lib.today = 100;
  check([lib.returnCopy('P1'), lib.fines['alice']], [500, 575]); // due day 42: 58 days late, capped at 500
  lib
    ..checkout('alice', 'D2')
    ..today = 200;
  lib.returnCopy('D2');
  check([lib.fines['alice'], error(() => lib.checkout('alice', 'P1'))], [1075, 'blocked: unpaid fines']);
  lib.payFine('alice', 1075);
  check(error(() => lib.checkout('alice', 'P1')), 'ok');
}
```

## 5. Walkthrough

- Alice (limit 2) borrows D1 and P1; a third loan is refused; Bob cannot take the copy Alice has.
- Carol cannot place a hold while D2 is on the shelf. After Bob borrows D2, Carol and Dave queue in order; duplicate holds and holds by someone who has the book are refused.
- Alice renews P1 twice (due day 14 -> 28 -> 42), then hits the limit; she cannot renew D1 because others are waiting.
- D1 comes back on day 17, three days late: 75 cents. It goes straight to Carol's hold shelf until day 24; Dave cannot take it; Carol can.
- D2 comes back on day 18 and is held for Dave until day 25. On day 26 the hold has expired; the queue is empty, so the copy becomes available and Dave is notified.
- P1 returned on day 100 is 58 days late: 1,450 cents, capped at 500. A second late return pushes Alice to 1,075 cents, above the 1,000 threshold; after paying, she can borrow again.

## 6. Concurrency

- Copy state changes are conditional updates (`UPDATE copies SET status = 'onLoan' WHERE barcode = ? AND status IN (...)`), so two desks cannot lend the same copy.
- Hold queue operations per title are serialized (row lock on the title's queue or a sequence number per hold); the daily expiry job runs once (leader or lease, see 19).
- Fines are ledger-style entries per member; the balance is their sum.

## 7. Extensibility

| Change | Where |
|---|---|
| Multiple branches | Copies get a location; holds choose a pickup branch; transfers between branches. |
| Member tiers | Loan limits, loan days and fine rates per tier. |
| E-books | Licenses per title (concurrent loans) and automatic return at expiry. |
| Notifications | Send through a notification service (see 07) instead of a log. |
| Lost items | A `lost` status and a replacement charge. |

## 8. Common mistakes in LLD rounds

- One `Book` class used for both the title and the physical copy.
- Returned copies going back to the shelf while people are waiting.
- Renewal rules ignoring the hold queue.
- No pickup deadline (a hold blocks a copy forever).

See [HLD.md](HLD.md) for the multi-branch system.
