# Implement Queue using Stacks

**Difficulty:** Easy | **Category:** Stacks / Design | **Pattern:** Two stacks with lazy transfer (amortized O(1)) | **Source:** LeetCode 232; Grind 75

## The problem

Implement a FIFO queue (`push`, `pop`, `peek`, `empty`) using only stack operations: push to top, pop from top, peek at top, size, is empty.

```
push(1), push(2), peek() -> 1, pop() -> 1, empty() -> false
```

## Step 1: One stack is backwards

A stack returns the **newest** element; a queue must return the **oldest**. Pouring a stack into another stack reverses it: the oldest element ends up on top. That reversal is the whole idea.

## Step 2: Naive version

Keep everything in one stack. For `pop`, pour everything into a second stack, pop the top, pour everything back. Correct, but O(n) per pop.

## Step 3: Do not pour back

Keep two stacks permanently:

- `inbox`: receives every `push`.
- `outbox`: holds elements in reversed order, oldest on top.

`pop` and `peek` read from `outbox`. Only when `outbox` is **empty** do we pour all of `inbox` into it.

**Why is it correct to wait until outbox is empty?** Everything in `outbox` is older than everything in `inbox` (they were pushed earlier and moved earlier). So while `outbox` has elements, its top is the oldest element overall.

**Why is it fast?** Each element is pushed to `inbox` once, moved to `outbox` once, and popped once: three O(1) operations over its lifetime. A single `pop` can cost O(n) (a big transfer), but n operations cost O(n) in total: **amortized O(1)**.

## Step 4: The code

<!-- CODE:START -->

Full source: [`implement_queue_using_stacks.dart`](implement_queue_using_stacks.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- Dart `List` with `add` / `removeLast` / `last` is a stack.
- `_refill` is the only place elements move between stacks, and only when `outbox` is empty.

## Step 5: Dry run

| operation | inbox (bottom to top) | outbox (bottom to top) | returns |
|---|---|---|---|
| push 1 | 1 | | |
| push 2 | 1 2 | | |
| peek | | 2 1 (poured) | 1 |
| pop | | 2 | 1 |
| push 3 | 3 | 2 | |
| pop | 3 | | 2 (no pour: outbox not empty) |
| pop | | | 3 (poured) |

## Complexity

- `push`, `empty`: **O(1)**.
- `pop`, `peek`: **amortized O(1)**, worst case O(n) for one call.
- Space: **O(n)**.

## Edge cases

- `pop` on an empty queue: undefined in the problem (LeetCode never does it); a real implementation should throw.
- Interleaved pushes and pops (the dry run).

## Common mistakes

- Pouring on every pop, even when `outbox` is not empty (breaks FIFO order).
- Pouring back after each pop (correct but O(n) per operation).

## Follow-ups you should be ready for

1. **Implement Stack using Queues (LeetCode 225).** One queue: after pushing x, rotate the previous n - 1 elements behind it, so x is at the front. O(n) push, O(1) pop.
2. **Explain amortized analysis.** The "each element moves at most three times" argument above is the aggregate method; the banker's method charges each push 3 credits.
3. **Functional (persistent) queues.** The same two-list idea is how immutable queues are built in functional languages.

## What to remember

Two stacks make a queue: push into one, pop from the other, and pour only when the output stack is empty. Each element moves once, so operations are amortized O(1).
