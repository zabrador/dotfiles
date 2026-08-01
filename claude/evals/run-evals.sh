#!/bin/sh
# Umbrella runner: run every eval tier that exists for a skill, or for all.
#
#   sh claude/evals/run-evals.sh <skill-name> [runs-per-trigger-query]
#   sh claude/evals/run-evals.sh all [runs-per-trigger-query]
#
# Tiers (each runs only if its case file exists in the skill's evals/ dir):
#   trigger-evals.json -> run-triggers.sh   (does the skill fire when it should?)
#   evals.json         -> run-behavioral.sh (does following it produce good results?)

set -u

here=$(cd "$(dirname "$0")" && pwd)
repo_root=$(cd "$here/../.." && pwd)
target=${1:?usage: run-evals.sh <skill-name>|all [runs-per-trigger-query]}
runs=${2:-2}

run_skill() {
  s=$1
  dir=$repo_root/claude/plugin/skills/$s
  if [ -f "$dir/evals/trigger-evals.json" ]; then
    echo "=== triggers: $s ===" >&2
    sh "$here/run-triggers.sh" "$s" "$runs"
  fi
  if [ -f "$dir/evals/evals.json" ]; then
    echo "=== behavioral: $s ===" >&2
    sh "$here/run-behavioral.sh" "$s"
  fi
  :
}

if [ "$target" = "all" ]; then
  for d in "$repo_root"/claude/plugin/skills/*/; do
    run_skill "$(basename "$d")"
  done
else
  run_skill "$target"
fi
