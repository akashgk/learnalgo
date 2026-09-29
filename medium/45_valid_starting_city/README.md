# Valid Starting City

**Difficulty:** Medium | **Category:** Greedy | **Pattern:** Circular prefix sums (gas station)

## Problem
Cities lie on a circular road. `distances[i]` is the distance from city `i` to city `i + 1` (wrapping), `fuel[i]` is the gallons available at city `i`, and the car gets `mpg` miles per gallon. You start with an empty tank at some city, refuel at each city, and must visit every city and return. Exactly one starting city works. Return its index.

## Building up the logic
1. Brute force: simulate from each city, O(n^2).
2. Define the per-leg surplus `g[i] = fuel[i] * mpg - distances[i]`. Total surplus over the loop is >= 0 (a valid start is guaranteed).
3. Start the simulation at city 0 and track the running surplus, even if it goes negative. Look at where it hits its **minimum**.
4. **Claim:** starting at the city right after that minimum works. Starting there shifts the whole running-surplus curve up by `-min`, so every point becomes >= 0, meaning the tank never runs dry.
5. One pass, no restarts.

## Complexity
- Time: O(n).
- Space: O(1).

## Interview notes
- LeetCode #134 (Gas Station). The other common O(n) explanation: whenever the running tank goes negative from a candidate start `s` at city `j`, no city in `s..j` can be a valid start, so jump the candidate to `j + 1`. Both are worth knowing; the "shift the curve" picture is the easiest to prove.
