# Tandem Bicycle

**Difficulty:** Easy | **Category:** Greedy | **Pattern:** Sort + pair opposite / same ends

## Problem
Each tandem bicycle has one red-shirt rider and one blue-shirt rider. Its speed equals the faster rider's speed. Given the two lists of speeds (same length) and a boolean `fastest`, pair riders to produce the **maximum** total speed if `fastest` is true, otherwise the **minimum**.

## Building up the logic
1. Each pair "wastes" its slower rider. To maximize the total you want to waste as little as possible, i.e. waste the slowest riders.
2. **Maximum:** the fastest rider overall should be paired with the slowest rider of the other color. Sort red ascending, blue descending, pair by index.
3. **Minimum:** you want to waste fast riders, so pair fast with fast. Sort both ascending, pair by index.
4. Exchange argument for the max case: if two big riders share a bike, one of them is wasted; swapping partners with a pair of two small riders never lowers the total.

## Complexity
- Time: O(n log n).
- Space: O(1) extra with in-place sort.

## Interview notes
- Same family as Class Photos and Task Assignment: sort, then pair ends. Recognize this pattern on sight.
