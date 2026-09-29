# Longest Most Frequent Prefix

**Difficulty:** Hard | **Category:** Tries | **Pattern:** Trie with prefix counts

## Problem
Given a list of non-empty strings, consider every prefix of every string. Find the prefixes shared by the largest number of strings, and return the longest of them.

```
["algoexpert", "algorithm", "frontendexpert", "mlexpert"]  ->  "algo"
(prefixes "a", "al", "alg", "algo" are each shared by 2 strings; "algo" is the longest)
```

> Statement note: this is my reading of AlgoExpert's problem (the statement is paywalled). Ties at the same count and length are broken by first occurrence here.

## Building up the logic
1. Brute force: count every prefix of every string in a hash map: O(n * m) prefixes, but each prefix string costs O(m) to build and hash: O(n * m^2).
2. A **trie** shares prefixes: each node represents one prefix, and incrementing a counter on every node you pass through while inserting gives "how many strings have this prefix" in O(1) per character. Total O(n * m).
3. Scan all nodes (DFS) and keep the best by (count, then length).
4. A node deeper in the trie never has a higher count than its parent, so for a fixed maximum count, the deepest node with that count wins.

## Complexity
- Time: O(n * m).
- Space: O(n * m) for the trie.

## Interview notes
- Pass-through counts on trie nodes also power autocomplete ranking, Shortest Unique Prefixes, and "count words with a given prefix" (LeetCode #1804, Implement Trie II).
