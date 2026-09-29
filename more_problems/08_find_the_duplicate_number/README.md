# Find the Duplicate Number

**Difficulty:** Medium | **Category:** Arrays / Linked lists | **Pattern:** Floyd's cycle detection on an implicit list | **Source:** LeetCode 287; Striver SDE sheet, NeetCode 150

## The problem

An array has `n + 1` integers, each in the range `[1, n]`. Exactly one value is repeated (it may appear two or more times). Find it **without modifying the array** and using **O(1) extra space**.

```
[1, 3, 4, 2, 2]   ->  2
[3, 1, 3, 4, 2]   ->  3
[3, 3, 3, 3, 3]   ->  3
```

### Why the constraints matter

Each constraint kills an easy solution, and interviewers state them precisely for that reason:

| Easy solution | Killed by |
|---|---|
| Hash set of seen values | O(1) space |
| Sort, then scan neighbors | no modifying (and O(n log n)) |
| Mark visited by negating `nums[abs(x)]` | no modifying |
| Sum formula `sum - n(n+1)/2` | the duplicate may appear more than twice, and some values may be missing |

## Step 1: Build a hidden linked list

Treat each index `i` as a node with an edge `i -> nums[i]`. Every value is in `[1, n]`, so every edge points to a valid index. Starting at index 0 and following edges must eventually **repeat** a node (there are only n + 1 nodes), so the walk ends in a **cycle**.

Where does the cycle start? The node where the cycle begins is entered from **two different nodes**: one from the path leading in, one from inside the cycle. Two indices pointing to the same node `v` means `nums[i] == nums[j] == v`: that is the duplicate. So **the entrance of the cycle is the duplicate value**.

Why start from index 0? No value equals 0, so no edge points to index 0. Index 0 is therefore never inside the cycle; it is a clean starting point on the "tail" of the list.

Example `[1, 3, 4, 2, 2]`: `0 -> 1 -> 3 -> 2 -> 4 -> 2 -> 4 -> ...`. Node 2 is entered from 3 and from 4. The duplicate is 2.

This is exactly AlgoExpert hard 35 Find Loop, on a list you never build.

## Step 2: Floyd's tortoise and hare

**Phase 1.** `slow` moves one step, `fast` moves two. Once both are in the cycle, the gap between them shrinks by one each step, so they meet.

**Phase 2.** Put one pointer back at the start (index 0). Move both one step at a time. They meet at the **cycle entrance**.

Why phase 2 works: let `F` be the distance from the start to the entrance, `C` the cycle length, and `a` the distance from the entrance to the meeting point. When they meet, slow has walked `F + a`, fast `2(F + a)`, and fast's extra distance is a whole number of laps: `F + a = kC`. So `F = kC - a`: walking `F` steps from the meeting point lands exactly on the entrance (you finish the lap and go around `k - 1` more times). Walking `F` steps from the start also lands on the entrance. They meet there.

## Step 3: Alternative with binary search on the value

Count how many elements are `<= mid`. If there were no duplicate in `[1, mid]`, at most `mid` elements could be `<= mid`. If the count is **greater** than `mid`, a value in `[1, mid]` is repeated (pigeonhole); otherwise the duplicate is in `[mid + 1, n]`. O(n log n) time, O(1) space, read-only. Easier to derive in an interview if you do not remember Floyd.

## Step 4: The code

<!-- CODE:START -->

Full source: [`find_the_duplicate_number.dart`](find_the_duplicate_number.dart) (run it with `dart run`).

```dart
// Find the Duplicate Number: n + 1 integers in [1, n], exactly one value repeated (possibly many times).
// Without modifying the array and in O(1) extra space: treat i -> nums[i] as a linked list
// and find the cycle entrance with Floyd's tortoise and hare. O(n) time, O(1) space.

int findDuplicate(List<int> nums) {
  // Phase 1: move slow one step and fast two steps until they meet inside the cycle.
  var slow = nums[0], fast = nums[nums[0]];
  while (slow != fast) {
    slow = nums[slow];
    fast = nums[nums[fast]];
  }
  // Phase 2: restart one pointer from the head; moving both one step, they meet at the entrance.
  slow = 0;
  while (slow != fast) {
    slow = nums[slow];
    fast = nums[fast];
  }
  return slow;
}

/// Alternative: binary search on the value, counting how many elements are <= mid.
/// O(n log n) time, O(1) space, also read-only.
int findDuplicateByCounting(List<int> nums) {
  var lo = 1, hi = nums.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) ~/ 2;
    final count = nums.where((x) => x <= mid).length;
    // With no duplicate in [1, mid], exactly mid values would be <= mid.
    if (count > mid) {
      hi = mid;
    } else {
      lo = mid + 1;
    }
  }
  return lo;
}
```

<!-- CODE:END -->

### Walkthrough of `findDuplicate`

- `slow = nums[0]`, `fast = nums[nums[0]]`: both have already moved (one and two steps), so the loop condition `slow != fast` is not trivially false at the start.
- Phase 2 resets `slow = 0` (the start node, not `nums[0]`). Both then move one step at a time.
- The returned node index **is** the duplicate value (the entrance is the node pointed to twice).

## Step 5: Dry run

`[1, 3, 4, 2, 2]`, edges: 0->1, 1->3, 2->4, 3->2, 4->2.

| Phase | slow | fast |
|---|---|---|
| init | 1 | 3 |
| 1 | 3 | 4 |
| 1 | 2 | 4 |
| 1 | 4 | 4 (meet) |
| 2 reset | 0 | 4 |
| 2 | 1 | 2 |
| 2 | 3 | 4 |
| 2 | 2 | 2 (meet, answer **2**) |

## Complexity

| Approach | Time | Space |
|---|---|---|
| Floyd | O(n) | O(1) |
| Binary search on value | O(n log n) | O(1) |
| Hash set | O(n) | O(n) (not allowed) |

## Edge cases

- `[1, 1]`: 0 -> 1 -> 1, a self-loop at 1. Both phases handle a cycle of length 1.
- All the same value: the cycle is a self-loop at that value.

## Common mistakes

- Starting phase 2 from `nums[0]` instead of `0`.
- Returning the meeting point of phase 1 (it is somewhere in the cycle, not necessarily the entrance).
- Using the sum formula (fails when the duplicate appears three or more times).

## Follow-ups you should be ready for

1. **Prove there must be a duplicate.** Pigeonhole: n + 1 values in n slots.
2. **Missing and repeating number (Striver).** Exactly one value twice and one missing: sum and sum-of-squares equations, or XOR partitioning.
3. **First Missing Positive (LeetCode 41).** Uses index-as-hash with in-place swaps when modifying *is* allowed.

## What to remember

Values that are valid indices define a function `i -> nums[i]`, which is a linked list in disguise. A value pointed to twice is a cycle entrance, and Floyd finds it in O(1) space.
