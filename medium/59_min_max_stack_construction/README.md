# Min Max Stack Construction

**Difficulty:** Medium | **Category:** Stacks | **Pattern:** Store aggregate state with each stack entry

## The problem

Implement a stack that supports `push`, `pop`, `peek`, `getMin`, and `getMax`, all in **O(1)** time.

```
push(5)          -> min 5, max 5
push(7)          -> min 5, max 7
push(2)          -> min 2, max 7
pop() returns 2  -> min 5, max 7
```

## Step 1: Why a single min variable is not enough

Keep `min` and `max` variables and update them on push: easy. The problem is **pop**. After popping the current minimum 2, what is the new minimum? The variable no longer knows; you would have to scan the whole stack: O(n).

## Step 2: The key observation

A stack only changes at the **top**. While an element sits in the stack, everything **below** it never changes. So the minimum and maximum of "this element and everything below it" never change either, as long as the element is in the stack.

So compute them once, at push time, and store them **with the element**:

```
push(x):
    newMin = min(x, top.min)   (or x if empty)
    newMax = max(x, top.max)
    push (x, newMin, newMax)
```

After a pop, the new top already carries the correct min and max for the remaining stack.

## Step 3: The code

<!-- CODE:START -->

Full source: [`min_max_stack_construction.dart`](min_max_stack_construction.dart) (run it with `dart run`).

```dart
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
```

<!-- CODE:END -->

### Walkthrough

- `_entries` is a list of named records `({int value, int min, int max})`.
- `peek`, `getMin`, `getMax` read fields of the top record: O(1).
- `pop` removes the top record and returns its value.
- `push` computes the new min and max from the previous top.

## Step 4: Dry run

| operation | entries (bottom -> top) as (value, min, max) | getMin, getMax |
|---|---|---|
| push 5 | (5, 5, 5) | 5, 5 |
| push 7 | (5,5,5), (7,5,7) | 5, 7 |
| push 2 | ..., (2,2,7) | 2, 7 |
| pop -> 2 | (5,5,5), (7,5,7) | 5, 7 |
| pop -> 7 | (5,5,5) | 5, 5 |

## Complexity

- **Time: O(1)** for every operation.
- **Space: O(n)** (three numbers per element).

## Space optimization

Use a separate **min stack** that only receives a value when it is `<=` the current minimum, and is popped only when the popped value equals its top (same for max). If the extremes rarely change, these stacks stay small. The `<=` (not `<`) matters: with duplicates of the minimum, each needs its own entry.

## Common mistakes

- Updating a single min variable and forgetting pops.
- In the optimized version, using `<` so duplicate minimums break after a pop.

## Follow-ups

1. **Min Stack (LeetCode #155):** only min.
2. **Max Stack (#716):** also supports `popMax()`, which removes the maximum from anywhere; needs a doubly linked list plus a sorted structure (TreeMap), O(log n).
3. **Min Queue:** implement a queue with two such stacks (amortized O(1) min).

## What to remember

When a stack needs aggregate queries, store the aggregate for "this element and everything below" alongside each element; pops then need no recomputation.
