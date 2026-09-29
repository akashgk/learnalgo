# Find Loop

**Difficulty:** Hard | **Category:** Linked Lists | **Pattern:** Floyd's cycle detection (tortoise and hare)

## The problem

A singly linked list contains a **loop**: the last node points back to some earlier node instead of null. Return the node where the loop begins, using O(1) extra space.

```
0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6
               ^              |
               |              v
               9 <- 8 <- 7 <--+

(9 points back to 4)  ->  node 4
```

## Step 1: Hash set solution

Walk the list and store every node in a set. The first node you see twice is the loop start. **O(n) time, O(n) space.** The problem asks for O(1) space.

## Step 2: Detect the loop: fast and slow pointers

`slow` moves one node per step, `fast` moves two. If there is a loop, both eventually enter it. Inside the loop, `fast` gains exactly one node on `slow` per step, so it must catch up: they **meet** somewhere inside the loop. (If there were no loop, `fast` would reach null.)

## Step 3: Find where the loop starts (the proof interviewers ask for)

Define:

- `D` = number of steps from the head to the loop start,
- `L` = loop length,
- `P` = how far into the loop (from the loop start) the pointers meet.

When they meet, slow has walked `D + P` steps. Fast has walked twice that, `2(D + P)`. Fast walked the same `D + P` plus some whole number of extra laps: `2(D + P) = D + P + kL`, so

```
D + P = kL      =>      D = kL - P
```

Read `D = kL - P` as: starting at the meeting point (P steps into the loop), walking `D` more steps brings you exactly to the loop start (you complete `k` laps minus the `P` you were ahead).

So: reset one pointer to the **head**, keep the other at the **meeting point**, and move both **one step at a time**. After `D` steps, the first pointer is at the loop start (it walked D from the head), and so is the second. They meet exactly there.

## Step 4: The code

<!-- CODE:START -->

Full source: [`find_loop.dart`](find_loop.dart) (run it with `dart run`).

```dart
// Find Loop: return the node where a linked list's cycle begins (a loop is guaranteed).
// Floyd's tortoise and hare. O(n) time, O(1) space.

class LinkedList {
  LinkedList(this.value, [this.next]);
  int value;
  LinkedList? next;
}

LinkedList findLoop(LinkedList head) {
  var slow = head.next!, fast = head.next!.next!;
  while (!identical(slow, fast)) {
    slow = slow.next!;
    fast = fast.next!.next!;
  }
  // Meeting point is k steps (the tail length, mod loop size) before the loop start.
  var p = head;
  while (!identical(p, fast)) {
    p = p.next!;
    fast = fast.next!;
  }
  return p;
}
```

<!-- CODE:END -->

### Walkthrough

- `slow` starts one step in, `fast` two steps in (so the loop condition can be "until they are identical").
- Phase 1 loop: advance until they meet. Non-null assertions (`!`) are safe because a loop is guaranteed.
- Phase 2: `p` from the head, `fast` from the meeting point, one step each, until identical.

## Step 5: Dry run (list 0..9, with 9 -> 4)

Here D = 4 and L = 6 (nodes 4..9).

Phase 1 positions after each step:

| step | slow | fast |
|---|---|---|
| start | 1 | 2 |
| 1 | 2 | 4 |
| 2 | 3 | 6 |
| 3 | 4 | 8 |
| 4 | 5 | 4 (8 -> 9 -> 4) |
| 5 | 6 | 6 |

They meet at node 6, which is P = 2 steps into the loop. Check: `D + P = 6 = 1 * L`. Correct.

Phase 2: `p` from 0, the other from 6. After 4 steps: `p` is at 4, the other went 6 -> 7 -> 8 -> 9 -> 4. They meet at **node 4**.

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## Common mistakes

- Starting both pointers at the head with the loop condition "while slow != fast" (exits immediately).
- In phase 2, moving the second pointer two steps at a time.

## Follow-ups

1. **Linked List Cycle I and II (LeetCode #141, #142).**
2. **Find the Duplicate Number (#287):** treat the array as a linked list `i -> nums[i]`; the duplicate is the loop start. A favorite interview connection.
3. **Loop length:** after the meeting, keep one pointer fixed and count steps until the other returns.

## What to remember

Floyd: fast and slow meet inside the loop. Then one pointer from the head and one from the meeting point, both at speed one, meet at the loop start, because `D = kL - P`.
