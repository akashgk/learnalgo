# Valid Starting City

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Circular prefix sums (gas station)

## The problem

Cities lie on a **circular** road. For each city `i`:

- `distances[i]` is the distance from city `i` to the next city (city `n - 1` connects back to city 0);
- `fuel[i]` is the fuel (in gallons) you pick up at city `i`.

Your car gets `mpg` miles per gallon. You start at some city with an **empty tank**, refuel there, drive to the next city, refuel, and so on, until you return to the start. You may never run out of fuel between cities. Exactly one starting city makes this possible. Return its index.

```
distances = [5, 25, 15, 10, 15], fuel = [1, 2, 1, 0, 3], mpg = 10  ->  4
```

## Step 1: Simplify to one number per leg

At city `i`, you gain `fuel[i] * mpg` miles of range and spend `distances[i]` driving to the next city. The net effect of leg `i` is the **surplus**:

```
g[i] = fuel[i] * mpg - distances[i]
```

For the example: `g = [10 - 5, 20 - 25, 10 - 15, 0 - 10, 30 - 15] = [5, -5, -5, -10, 15]`. The total is 0 here (a valid start is guaranteed, so the total is never negative).

A start city `s` works if the running sum of `g` starting at `s` never goes negative.

## Step 2: Brute force

Try every start and simulate the whole loop: O(n^2).

## Step 3: The trick: look at the lowest point

Start (hypothetically) at city 0 and write down the running surplus when **arriving** at each city, even if it goes negative:

| arriving at city | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| running surplus | 0 | 5 | 0 | -5 | **-15** |

The lowest point is at city 4 (-15).

**Claim:** starting at the city where the running surplus is lowest works. Starting there instead of at city 0 shifts the whole curve up by 15 (the negative of the minimum). The minimum becomes 0, so every point is at least 0: you never run out of fuel. And because the total surplus is non-negative, the wrap-around part of the loop stays non-negative too.

One pass, no restarts.

## Step 4: The code

<!-- CODE:START -->

Full source: [`valid_starting_city.dart`](valid_starting_city.dart) (run it with `dart run`).

```dart
// Valid Starting City (circular route, gas station variant).
// Track fuel surplus with no initial fuel; the valid start is the city just after the
// point where the running surplus is lowest. O(n) time, O(1) space.

int validStartingCity(List<int> distances, List<int> fuel, int mpg) {
  var surplus = 0, minSurplus = 0, start = 0;
  for (var city = 1; city < distances.length; city++) {
    // Arrive at `city` after leaving city - 1.
    surplus += fuel[city - 1] * mpg - distances[city - 1];
    if (surplus < minSurplus) {
      minSurplus = surplus;
      start = city;
    }
  }
  return start;
}
```

<!-- CODE:END -->

### Walkthrough

- `surplus` is the running surplus when arriving at `city` (starting from city 0 with 0).
- `surplus += fuel[city - 1] * mpg - distances[city - 1];` adds the leg that arrives at `city`.
- `if (surplus < minSurplus)` tracks the lowest point and remembers the city where it happens.
- `start` starts at 0 (if the running surplus never dips below 0, city 0 works).

## Step 5: Dry run

| city (arriving) | leg added | surplus | min, start |
|---|---|---|---|
| 0 | | 0 | 0, 0 |
| 1 | 10 - 5 = 5 | 5 | 0, 0 |
| 2 | 20 - 25 = -5 | 0 | 0, 0 |
| 3 | 10 - 15 = -5 | -5 | -5, 3 |
| 4 | 0 - 10 = -10 | -15 | -15, 4 |

Answer: 4. Check by simulation from city 4: tank after refuel 30 miles, drive 15 -> 15; city 0: +10 = 25, drive 5 -> 20; city 1: +20 = 40, drive 25 -> 15; city 2: +10 = 25, drive 15 -> 10; city 3: +0, drive 10 -> 0. Never negative. Correct.

## Complexity

- **Time: O(n)**.
- **Space: O(1)**.

## The other classic explanation

Start at city 0 with a tank. Whenever the tank goes negative on arrival at city `j`, no city from the current candidate up to `j` can be a valid start (each would arrive at `j` with even less fuel), so set the candidate to `j`. This is equivalent and also O(n). Knowing both explanations helps you answer follow-up questions.

## Common mistakes

- Off-by-one: the surplus when arriving at `city` uses the fuel and distance of `city - 1`.
- Resetting the running sum (fine in the second explanation, wrong in the "minimum point" version).

## Follow-ups

1. **Gas Station (LeetCode #134):** identical, but return -1 if the total surplus is negative.
2. **Minimum starting fuel instead of a starting city:** `-min(0, lowest running surplus)` for a fixed start.

## What to remember

On a circular route with a non-negative total, start right where the running balance hits its minimum: shifting the curve so that minimum is 0 keeps everything non-negative.
