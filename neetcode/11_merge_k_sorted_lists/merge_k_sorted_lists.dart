// Merge k Sorted Lists: merge k sorted linked lists into one sorted list.
// Min-heap holding the current head of each list: pop the smallest, push its successor.
// O(N log k) time for N total nodes, O(k) extra space.

class ListNode {
  ListNode(this.value, [this.next]);
  int value;
  ListNode? next;
}

ListNode? mergeKLists(List<ListNode?> lists) {
  final heap = _MinHeap<ListNode>((a, b) => a.value.compareTo(b.value));
  for (final head in lists) {
    if (head != null) heap.push(head);
  }
  final dummy = ListNode(0);
  var tail = dummy;
  while (heap.isNotEmpty) {
    final node = heap.pop(); // smallest head among all lists
    tail.next = node;
    tail = node;
    if (node.next != null) heap.push(node.next!); // its list's next candidate
  }
  return dummy.next;
}

/// Alternative: divide and conquer, merging lists in pairs round by round. Also O(N log k) time:
/// log k rounds, each touching every node once. O(k) extra space for the list of heads.
ListNode? mergeKListsPairwise(List<ListNode?> lists) {
  if (lists.isEmpty) return null;
  var current = [...lists];
  while (current.length > 1) {
    current = [
      for (var i = 0; i < current.length; i += 2)
        i + 1 < current.length ? _mergeTwo(current[i], current[i + 1]) : current[i],
    ];
  }
  return current[0];
}

ListNode? _mergeTwo(ListNode? a, ListNode? b) {
  final dummy = ListNode(0);
  var tail = dummy;
  while (a != null && b != null) {
    if (a.value <= b.value) {
      tail.next = a;
      a = a.next;
    } else {
      tail.next = b;
      b = b.next;
    }
    tail = tail.next!;
  }
  tail.next = a ?? b;
  return dummy.next;
}

class _MinHeap<T> {
  _MinHeap(this._compare);
  final int Function(T, T) _compare;
  final _items = <T>[];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(T item) {
    _items.add(item);
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_compare(_items[parent], _items[i]) <= 0) break;
      _swap(i, parent);
      i = parent;
    }
  }

  T pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = l + 1;
        var m = i;
        if (l < _items.length && _compare(_items[l], _items[m]) < 0) m = l;
        if (r < _items.length && _compare(_items[r], _items[m]) < 0) m = r;
        if (m == i) break;
        _swap(i, m);
        i = m;
      }
    }
    return top;
  }

  void _swap(int i, int j) {
    final t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;
  }
}

ListNode? fromList(List<int> values) {
  ListNode? head;
  for (final v in values.reversed) {
    head = ListNode(v, head);
  }
  return head;
}

List<int> toList(ListNode? head) => [for (var c = head; c != null; c = c.next) c.value];

void check(Object? got, Object? want) {
  if ('$got' != '$want') throw StateError('expected $want, got $got');
  print('ok: $got');
}

void main() {
  for (final f in [mergeKLists, mergeKListsPairwise]) {
    check(
      toList(
        f([
          fromList([1, 4, 5]),
          fromList([1, 3, 4]),
          fromList([2, 6]),
        ]),
      ),
      [1, 1, 2, 3, 4, 4, 5, 6],
    );
    check(toList(f([])), []);
    check(toList(f([null])), []);
    check(
      toList(
        f([
          null,
          fromList([-1, 5]),
          null,
          fromList([0]),
        ]),
      ),
      [-1, 0, 5],
    );
  }
}
