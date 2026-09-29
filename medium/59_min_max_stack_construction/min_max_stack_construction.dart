// Min Max Stack: push/pop/peek/getMin/getMax all O(1).
// Each entry stores the min and max of the stack at the time it was pushed.

class MinMaxStack {
  final _entries = <({int value, int min, int max})>[];

  int peek() => _entries.last.value;
  int getMin() => _entries.last.min;
  int getMax() => _entries.last.max;

  int pop() => _entries.removeLast().value;

  void push(int number) {
    if (_entries.isEmpty) {
      _entries.add((value: number, min: number, max: number));
      return;
    }
    final top = _entries.last;
    _entries.add((value: number, min: number < top.min ? number : top.min, max: number > top.max ? number : top.max));
  }
}

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  final s = MinMaxStack()..push(5);
  check([s.getMin(), s.getMax(), s.peek()], [5, 5, 5]);
  s.push(7);
  check([s.getMin(), s.getMax(), s.peek()], [5, 7, 7]);
  s.push(2);
  check([s.getMin(), s.getMax(), s.peek()], [2, 7, 2]);
  check(s.pop(), 2);
  check(s.pop(), 7);
  check([s.getMin(), s.getMax(), s.peek()], [5, 5, 5]);
}
