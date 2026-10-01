// Implement Queue using Stacks: push, pop, peek, empty using only stack operations.
// Two stacks: `inbox` receives pushes; `outbox` serves pops in FIFO order. When outbox is empty,
// pour inbox into it (reversing the order). Each element moves at most once: amortized O(1).

class MyQueue {
  final _inbox = <int>[]; // newest on top
  final _outbox = <int>[]; // oldest on top

  void push(int x) => _inbox.add(x);

  int pop() {
    _refill();
    return _outbox.removeLast();
  }

  int peek() {
    _refill();
    return _outbox.last;
  }

  bool empty() => _inbox.isEmpty && _outbox.isEmpty;

  /// Only pour when outbox is empty; otherwise its top is still the oldest element.
  void _refill() {
    if (_outbox.isEmpty) {
      while (_inbox.isNotEmpty) {
        _outbox.add(_inbox.removeLast());
      }
    }
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final q = MyQueue()
    ..push(1)
    ..push(2);
  check(q.peek(), 1);
  check(q.pop(), 1);
  check(q.empty(), false);
  q.push(3); // goes to inbox; outbox still holds 2
  check(q.pop(), 2);
  check(q.pop(), 3);
  check(q.empty(), true);
}
