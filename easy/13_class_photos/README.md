# Class Photos

**Difficulty:** Easy | **Category:** Greedy | **Pattern:** Sort both lists, compare pairwise

## The problem

There are as many students in red shirts as in blue shirts. For a class photo:

- students stand in two rows of equal length;
- all students in a row wear the same color;
- every student in the back row must be **strictly taller** than the student directly in front of them.

Given the two lists of heights, return whether such a photo is possible. You may arrange students within a row in any order.

```
red  = [5, 8, 1, 3, 4]
blue = [6, 9, 2, 4, 5]   ->  true
(blue in the back: 9 6 5 4 2 behind red 8 5 4 3 1)
```

## Step 1: Work an example by hand

**Which color goes in the back?** Look at the single tallest student overall (9, blue). If that student stood in the front row, someone behind them would have to be taller than 9, which is impossible. So the tallest student's color must be the back row. If both colors share the same maximum height, neither can stand behind the other: impossible.

**How do we pair students?** Sort both rows from tallest to shortest and put them in the same order:

```
back  (blue): 9  6  5  4  2
front (red) : 8  5  4  3  1
```

Every back student is taller than the one in front, so the answer is true.

## Step 2: Brute force

Try every arrangement of the front row against every arrangement of the back row: O(n! * n!). Or, for a fixed back row, try all n! matchings. Clearly we need a smarter pairing rule.

## Step 3: Why sorted pairing is optimal

Claim: if any valid arrangement exists, then pairing the i-th tallest back student with the i-th tallest front student is valid.

Argument: suppose the sorted pairing fails at position i, meaning `back[i] <= front[i]` (both sorted descending). Look at the i + 1 front students `front[0..i]`; each of them is at least `front[i]`. Each needs a back student taller than them, so each needs someone taller than `front[i]`. But only `back[0..i-1]` (i students) can possibly be taller than `front[i]`, since `back[i] <= front[i]` and the rest are shorter. i + 1 students need i helpers: by the pigeonhole principle, impossible. So if sorted pairing fails, **every** pairing fails.

## Step 4: The code

<!-- CODE:START -->

Full source: [`class_photos.dart`](class_photos.dart) (run it with `dart run`).

```dart
// Class Photos
// Sort both colors; the back row is whichever group has the taller tallest student.
// Every back student must be strictly taller than the student in front. O(n log n) time.

bool classPhotos(List<int> redShirtHeights, List<int> blueShirtHeights) {
  final red = [...redShirtHeights]..sort((a, b) => b - a);
  final blue = [...blueShirtHeights]..sort((a, b) => b - a);
  final redInBack = red[0] > blue[0];
  final (back, front) = redInBack ? (red, blue) : (blue, red);
  for (var i = 0; i < back.length; i++) {
    if (back[i] <= front[i]) return false;
  }
  return true;
}
```

<!-- CODE:END -->

### Walkthrough

- `..sort((a, b) => b - a)` sorts each copy in **descending** order, so index 0 is the tallest.
- `final redInBack = red[0] > blue[0];` decides the back row from the tallest students. If they are equal, `redInBack` is false and blue goes in back; the loop then compares `blue[0] <= red[0]` (equal) and correctly returns false.
- `final (back, front) = redInBack ? (red, blue) : (blue, red);` picks both rows at once with a Dart record.
- The loop checks the strict inequality at every position.

## Step 5: Dry run

red sorted: `[8, 5, 4, 3, 1]`, blue sorted: `[9, 6, 5, 4, 2]`. `red[0] = 8 < 9`, so blue is in back.

| i | back (blue) | front (red) | back > front? |
|---|---|---|---|
| 0 | 9 | 8 | yes |
| 1 | 6 | 5 | yes |
| 2 | 5 | 4 | yes |
| 3 | 4 | 3 | yes |
| 4 | 2 | 1 | yes |

Result: `true`.

## Complexity

- **Time: O(n log n)** for sorting.
- **Space: O(1)** extra with in-place sorts (O(n) here because the code copies).

## Edge cases

- Tallest students have equal height: false.
- Any equal pair later in the sorted order: false (strictly taller is required).

## Common mistakes

- Deciding the back row by comparing the **sums** or **averages** of heights instead of the tallest student.
- Using `>=` instead of `>`.
- Sorting in place when the caller does not expect mutation (mention it).

## Follow-ups

1. **Unequal row sizes:** the back row can be longer; sort both and match the front row against the tallest back students.
2. **Tandem Bicycle (easy 14)** and **Task Assignment (medium 44)** use the same "sort both, pair by rank" idea.

## What to remember

When two groups must be matched under an ordering constraint, sort both and match by rank. Prove it with a pigeonhole or exchange argument.
