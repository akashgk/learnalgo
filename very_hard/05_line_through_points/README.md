# Line Through Points

**Difficulty:** Very Hard | **Category:** Arrays | **Pattern:** Anchor point + hash map of exact slopes

## Problem
Given distinct 2D integer points, return the maximum number of points that lie on a single straight line.

## Building up the logic
1. Brute force: every pair defines a line; count points on it: O(n^3).
2. **Anchor:** fix point `i`. Every line through `i` is identified by its **slope**. Points with the same slope from `i` are on the same line. Count them in a hash map: O(n) per anchor, O(n^2) total.
3. **Precision trap:** floating-point slopes (`dy / dx`) can give false mismatches (and vertical lines divide by zero). Represent the slope exactly as the reduced fraction `(dy, dx)`: divide both by `gcd(|dy|, |dx|)` and fix a canonical sign (make `dx` positive, or for vertical lines make `dy` positive).
4. Answer: the max count over all anchors and slopes, plus one for the anchor itself.
5. Only points after `i` need to be considered; any line containing earlier points was already counted from an earlier anchor.

## Complexity
- Time: O(n^2 log V) including gcd (V = coordinate range).
- Space: O(n).

## Interview notes
- LeetCode #149 (Max Points on a Line). If duplicate points are allowed, count duplicates of the anchor separately and add them to every slope bucket.
- Explaining why floats are dangerous here is a key signal.
