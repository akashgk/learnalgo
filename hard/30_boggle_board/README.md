# Boggle Board

**Difficulty:** Hard | **Category:** Graphs | **Pattern:** Trie + backtracking DFS on a grid

## Problem
Given a 2D board of characters and a list of words, return the words that can be formed on the board. A word is formed by a path of adjacent cells (horizontally, vertically, or diagonally), and a cell cannot be used twice within the same word.

## Building up the logic
1. **One word at a time:** DFS from every cell for each word. That repeats the same board exploration for every word, and words that share prefixes (`simp`, `simple`) are explored separately.
2. **Search all words at once:** put the words in a **trie**. A DFS path on the board corresponds to a walk down the trie. If the current path is not a prefix of any word, the trie has no child for it and the DFS stops immediately. That pruning is the whole point.
3. Store the full word at its terminal trie node so you can record it without rebuilding the string from the path.
4. Backtracking: mark the cell visited on entry and unmark on exit, because other paths may need it.
5. Use a set for results: the same word can be found along several paths.

## Complexity
- Build trie: O(total characters in words).
- Search: O(w * h * 8^s) in the worst case, where s is the length of the longest word (each step branches up to 8 ways); pruning makes the practical cost far lower.
- Space: O(total word characters + w * h) for the trie, visited grid, and recursion.

## Interview notes
- LeetCode #212 (Word Search II), a very common Google/Amazon hard problem. Extra optimization interviewers like: delete a word from the trie once found, and remove empty trie branches, so later searches prune even more.
- #79 (Word Search) is the single-word version without a trie.
