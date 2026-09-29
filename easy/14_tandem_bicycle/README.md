# Tandem Bicycle

**Difficulty:** Easy | **Category:** Greedy | **Pattern:** Sort, then pair opposite ends or same ends

## The problem

A tandem bicycle has two riders: one in a red shirt and one in a blue shirt. The bike's speed is the speed of the **faster** rider (the slower one just follows). You are given the red riders' speeds, the blue riders' speeds (same count), and a boolean `fastest`.

- If `fastest` is true, pair riders to **maximize** the total speed of all bikes.
- If false, pair them to **minimize** the total speed.

```
red  = [5, 5, 3, 9, 2]
blue = [3, 6, 7, 2, 1]
fastest = true   ->  32
fastest = false  ->  25
```

## Step 1: Work an example by hand

Every bike "wastes" its slower rider: only the faster one counts.

- To **maximize**, waste the slowest riders. Pair the fastest person with the slowest person of the other color, so a slow rider is hidden behind a fast one.
- To **minimize**, waste the fast riders. Pair fast with fast, so a fast rider is hidden behind another fast one.

Maximize: red ascending `[2, 3, 5, 5, 9]`, blue descending `[7, 6, 3, 2, 1]`. Bikes: max(2,7)=7, max(3,6)=6, max(5,3)=5, max(5,2)=5, max(9,1)=9. Total 32.

Minimize: both ascending: red `[2, 3, 5, 5, 9]`, blue `[1, 2, 3, 6, 7]`. Bikes: 2, 3, 5, 6, 9. Total 25.

## Step 2: Brute force

Try all n! ways to pair red riders with blue riders. O(n! * n).

## Step 3: Why the greedy pairing is optimal (maximum case)

The fastest rider overall, say speed `F`, always counts no matter who they ride with. Their partner never counts (unless equal). So the partner should be the rider whose speed is least useful: the slowest one of the other color. Remove both and repeat on the rest.

Exchange argument: suppose two fast riders `a` and `b` share a bike (only `max(a, b)` counts) and two slow riders `c` and `d` share another (only `max(c, d)` counts). Re-pair as `(a, c)` and `(b, d)`: the total becomes `a + b`, which is at least `max(a, b) + max(c, d)` because `min(a, b) >= max(c, d)`. Never worse. Repeating this swap reaches the sorted opposite-ends pairing.

The minimum case is symmetric: pairing fast with fast hides as much speed as possible.

## Step 4: The code

<!-- CODE:START -->

Full source: [`tandem_bicycle.dart`](tandem_bicycle.dart) (run it with `dart run`).

```dart
// Tandem Bicycle
// A tandem's speed is max(rider speeds). Fastest total: pair fastest with slowest.
// Slowest total: pair fastest with fastest. O(n log n) time.

int tandemBicycle(List<int> redShirtSpeeds, List<int> blueShirtSpeeds, bool fastest) {
  final red = [...redShirtSpeeds]..sort();
  final blue = [...blueShirtSpeeds]..sort();
  if (fastest) blue.sort((a, b) => b - a); // reverse one list to pair opposite ends
  var total = 0;
  for (var i = 0; i < red.length; i++) {
    total += red[i] > blue[i] ? red[i] : blue[i];
  }
  return total;
}
```

<!-- CODE:END -->

### Walkthrough

- Both lists are copied and sorted ascending.
- `if (fastest) blue.sort((a, b) => b - a);` reverses blue so index `i` pairs the i-th slowest red with the i-th fastest blue (opposite ends). For the minimum, both stay ascending (same ends).
- `total += red[i] > blue[i] ? red[i] : blue[i];` adds the faster rider's speed for bike `i`.

## Step 5: Dry run (fastest = true)

| i | red (asc) | blue (desc) | bike speed | total |
|---|---|---|---|---|
| 0 | 2 | 7 | 7 | 7 |
| 1 | 3 | 6 | 6 | 13 |
| 2 | 5 | 3 | 5 | 18 |
| 3 | 5 | 2 | 5 | 23 |
| 4 | 9 | 1 | 9 | 32 |

## Complexity

- **Time: O(n log n)** for sorting.
- **Space: O(1)** extra if sorting in place (O(n) here, due to copies).

## Common mistakes

- Pairing opposite ends for the minimum case too.
- Sorting only one list.
- Using `min` instead of `max` for the bike speed.

## Follow-ups

1. **Class Photos (easy 13)** and **Task Assignment (medium 44):** the same sort-and-pair family.
2. **Boats to Save People (LeetCode #881):** pair the heaviest with the lightest if they fit together.

## What to remember

When each pair's value is determined by one member (the max or min), decide who should be "wasted", then pair opposite ends (to waste the weak) or the same ends (to waste the strong).
