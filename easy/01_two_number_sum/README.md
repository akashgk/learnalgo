# Two Number Sum

**Difficulty:** Easy | **Category:** Arrays | **Pattern:** Hash set / Two pointers

## The problem

You get an array of **distinct** integers and a target sum. If any two numbers in the array add up to the target, return them (in any order). If no pair exists, return an empty array. You may not add a number to itself.

```
array = [3, 5, -4, 8, 11, 1, -1, 6], target = 10   ->  [11, -1]
array = [4, 6], target = 10                         ->  [4, 6]
array = [4, 6, 1], target = 5                       ->  [4, 1]
array = [1, 2, 3], target = 100                     ->  []
```

### Clarifying questions to ask

Ask these before writing any code. Interviewers expect it, and each answer changes the solution:

| Question | Why it matters |
|---|---|
| Can values repeat? | With duplicates, `[5, 5]` and target 10 is a valid pair, and "have I seen this value" logic must handle it. (Here: distinct.) |
| Return values or indices? | Returning indices means you cannot sort (sorting loses positions) unless you sort pairs `(value, index)`. |
| Is the array sorted? | If yes, two pointers gives O(1) extra space for free. |
| Exactly one answer, or all pairs? | "All pairs" changes the output size and the loop's stopping condition. |
| Negative numbers? | They break some shortcuts (for example "skip numbers bigger than target"). Here: allowed. |

## Step 1: Work an example by hand

Take `[3, 5, -4, 8, 11, 1, -1, 6]` and target `10`. How would **you** find the pair on paper?

You would probably look at `3` and think "I need a `7`". Scan the list: no `7`. Look at `5`, need a `5`: only one `5`, and you cannot reuse it. Look at `-4`, need `14`: no. Look at `8`, need `2`: no. Look at `11`, need `-1`: yes, there it is.

Notice what you actually did at each step. You did not "try pairs". You computed **the one number that would complete the pair** and then **searched for it**. That observation is the entire problem. Hold on to it.

## Step 2: Brute force

The most direct translation of the question: try every pair.

```dart
for (var i = 0; i < array.length; i++) {
  for (var j = i + 1; j < array.length; j++) {
    if (array[i] + array[j] == target) return [array[i], array[j]];
  }
}
return [];
```

- Starting `j` at `i + 1` does two things: never pairs a number with itself, and never checks the same pair twice.
- Time: the inner loop runs `(n-1) + (n-2) + ... + 1 = n(n-1)/2` times, so **O(n^2)**.
- Space: **O(1)**.

Always say the brute force out loud in an interview, with its complexity. It proves you understand the problem, and it gives you something correct to fall back on.

## Step 3: Optimize

Ask the standard optimization questions: where is the **B**ottleneck, what work is **U**nnecessary, what work is **D**uplicated?

**Bottleneck.** For each `array[i]`, the inner loop is a linear search for the value `target - array[i]`. We do n searches, each O(n). The bottleneck is the **search**.

**What makes a search fast?** A hash set answers "is value v present?" in O(1) on average. So if all values were in a set, each search would cost O(1) and the whole thing would be O(n).

This is exactly what you did by hand in Step 1: compute the complement, look it up.

### Approach A: hash set (optimal time)

Two ways to use the set:

1. **Two passes:** put every number in the set, then for each `x` check whether `target - x` is in the set. Careful: if `x == target - x` (for example `x = 5`, target `10`), the set contains `x` itself and you would wrongly pair `5` with itself. You need an extra check.
2. **One pass (better):** walk the array once. For each `x`, **first** check whether its complement is among the numbers **already seen**, **then** add `x`. Because `x` is not yet in the set when you check, it can never pair with itself. The edge case disappears by construction.

Why does one pass still find every pair? For a valid pair `(a, b)` where `a` comes first, by the time you reach `b`, `a` is already in the set. So the pair is found when you visit its second element.

### Approach B: sort + two pointers (optimal space)

If the interviewer says "now do it with O(1) extra space", sort the array and use two pointers.

Sorted: `[-4, -1, 1, 3, 5, 6, 8, 11]`. Put `lo` at the smallest value and `hi` at the largest.

- If `a[lo] + a[hi]` is **too small**, the only way to increase the sum is to move `lo` right. Moving `hi` left would only make it smaller.
- If it is **too big**, move `hi` left.
- If it is equal, done.

**Why is it safe to discard an element?** Suppose the sum is too small. `a[lo]` paired with the **largest** remaining number is still too small, so `a[lo]` paired with any smaller number is also too small. `a[lo]` cannot be part of any answer; throwing it away loses nothing. The same argument works for `a[hi]` when the sum is too big. Every step discards one element that provably cannot be in a solution, so after at most n steps you are done.

This "discard an element that cannot be in any answer" argument is the proof behind every two-pointer solution. You will reuse it in Three Number Sum, Four Number Sum, Smallest Difference, and Water Area.

## Step 4: The code

<!-- CODE:START -->

Full source: [`two_number_sum.dart`](two_number_sum.dart) (run it with `dart run`).

```dart
// Two Number Sum
// Optimal: single pass with a hash set. O(n) time, O(n) space.
// Alternative: sort + two pointers. O(n log n) time, O(1) extra space.

/// Returns the pair that sums to [target], or an empty list if none exists.
List<int> twoNumberSum(List<int> array, int target) {
  final seen = <int>{};
  for (final x in array) {
    final need = target - x;
    if (seen.contains(need)) return [need, x];
    seen.add(x);
  }
  return [];
}

/// Two-pointer variant. Sorts a copy so the caller's list is untouched.
List<int> twoNumberSumSorted(List<int> array, int target) {
  final a = [...array]..sort();
  var lo = 0, hi = a.length - 1;
  while (lo < hi) {
    final sum = a[lo] + a[hi];
    if (sum == target) return [a[lo], a[hi]];
    if (sum < target) {
      lo++;
    } else {
      hi--;
    }
  }
  return [];
}
```

<!-- CODE:END -->

### Walkthrough of `twoNumberSum`

- `final seen = <int>{};` creates an empty hash set of integers. It holds the numbers we have already visited.
- `for (final x in array)` visits each number once, left to right.
- `final need = target - x;` is the complement: the only value that can pair with `x`.
- `if (seen.contains(need)) return [need, x];` is an average O(1) lookup. `need` was seen earlier, so it is a different element from `x`.
- `seen.add(x);` records `x` **after** the check. Swapping these two lines reintroduces the "pair with itself" bug.
- `return [];` runs only if no pair was found after visiting everything.

### Walkthrough of `twoNumberSumSorted`

- `final a = [...array]..sort();` sorts a **copy**. Sorting the caller's array in place would be a side effect nobody asked for. Mention this choice; if the interviewer allows mutation, sort in place and the extra space really is O(1).
- `var lo = 0, hi = a.length - 1;` sets the two pointers at the smallest and largest values.
- `while (lo < hi)` uses strict `<`. At `lo == hi` both pointers are on the same element, which cannot pair with itself.
- The three branches (equal, too small, too big) are exactly the argument from Step 3.

## Step 5: Dry run

Hash set version, `array = [3, 5, -4, 8, 11, 1, -1, 6]`, `target = 10`:

| x | need = 10 - x | need in seen? | seen after this step |
|---|---|---|---|
| 3 | 7 | no | {3} |
| 5 | 5 | no (5 is not added yet) | {3, 5} |
| -4 | 14 | no | {3, 5, -4} |
| 8 | 2 | no | {3, 5, -4, 8} |
| 11 | -1 | no | {3, 5, -4, 8, 11} |
| 1 | 9 | no | {3, 5, -4, 8, 11, 1} |
| -1 | 11 | **yes** | return `[11, -1]` |

Two-pointer version on the sorted copy `[-4, -1, 1, 3, 5, 6, 8, 11]`:

| lo | hi | a[lo] + a[hi] | action |
|---|---|---|---|
| 0 | 7 | -4 + 11 = 7 | too small, `lo++` |
| 1 | 7 | -1 + 11 = 10 | found `[-1, 11]` |

## Complexity

| Approach | Time | Space | Why |
|---|---|---|---|
| Brute force | O(n^2) | O(1) | n(n-1)/2 pairs checked |
| Hash set, one pass | O(n) average | O(n) | n iterations, each an O(1) average set lookup and insert; the set can hold up to n values |
| Sort + two pointers | O(n log n) | O(1) extra (O(n) here, because we copy) | sorting dominates; the pointer walk is O(n) because each step moves one pointer inward |

"Average" matters for the hash set: in the worst case (every value collides in the hash table) lookups degrade to O(n). In interviews, say "O(n) expected time" once, and move on.

## Edge cases

| Input | Expected | Handled by |
|---|---|---|
| `[]` or one element | `[]` | loop finds nothing |
| `[5]`, target `10` | `[]` | check-before-insert (5 never sees itself) |
| no valid pair | `[]` | final `return []` |
| negative numbers | works | nothing special: complements can be negative |

## Common mistakes

- Adding `x` to the set **before** checking it: pairs a number with itself.
- Sorting when the problem asks for **indices**: positions are lost.
- In the two-pointer version, writing `while (lo <= hi)`: allows `lo == hi`, pairing an element with itself.
- Claiming the hash solution is "O(1) space": the set grows with the input.

## Follow-ups you should be ready for

1. **Return indices (LeetCode #1).** Use a `Map<int, int>` from value to index instead of a set.
2. **The array is already sorted.** Skip the sort. Two pointers gives O(n) time and O(1) space, strictly better than the hash set.
3. **Return all pairs, with duplicates allowed.** Store counts in a map, or use two pointers and skip runs of equal values after each match.
4. **Design a class with `add(number)` and `find(value)` (LeetCode #170).** Trade-off question: fast `add` (store counts, O(n) `find`) versus fast `find` (store all pair sums, O(n) `add`). Ask which operation is more frequent.
5. **Three or four numbers.** Fix one number and reduce to Two Number Sum: see Three Number Sum (medium 01) and Four Number Sum (hard 01).

## Related problems

- Three Number Sum (medium 01): fix one number, then two pointers.
- Four Number Sum (hard 01): pair sums in a hash map.
- Smallest Difference (medium 02): two pointers across two sorted arrays.
- Sweet And Savory (medium 14): two pointers with a "do not exceed" constraint.

## What to remember

When a brute force contains an inner loop that **searches for a specific value**, replace the search with a hash lookup. When the input is (or can be) sorted, two pointers can replace the hash set and save memory, justified by the "discard an element that cannot be in any answer" argument.
