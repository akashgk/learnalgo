#!/usr/bin/env bash
# Runs every solution file. Each file's main() throws on a failed check,
# so a non-zero exit means a broken solution.
# Usage: tool/run_all.sh            (all)
#        tool/run_all.sh medium     (one difficulty folder)
set -uo pipefail
cd "$(dirname "$0")/.."
filter="${1:-}"
pass=0; fail=0; failed=()
for f in $(ls -d easy/*/*.dart medium/*/*.dart hard/*/*.dart very_hard/*/*.dart 2>/dev/null | grep "${filter}"); do
  if out=$(dart run "$f" 2>&1); then
    pass=$((pass+1))
  else
    fail=$((fail+1)); failed+=("$f"); echo "FAIL $f"; echo "$out" | tail -5
  fi
done
echo "passed: $pass  failed: $fail"
[ "$fail" -eq 0 ]
