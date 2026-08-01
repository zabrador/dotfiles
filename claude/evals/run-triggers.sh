#!/bin/sh
# Trigger evals: does a skill's description get consulted when it should?
#
# Cases live at claude/plugin/skills/<skill>/evals/trigger-evals.json as
# [{"query": "...", "should_trigger": true|false}, ...]. Each query runs in a
# fresh git fixture with the skill's description injected the way
# skill-creator's runner does it (a command file the classifier can see).
#
# Contract: a query "triggered" when the Skill tool is invoked with the
# injected name within the first MAX_CALLS tool calls. This deliberately
# differs from skill-creator's first-call-only contract: the git skills
# themselves mandate inspecting state (git status/diff) before acting, so a
# leading Bash call is correct behavior, not a routing miss.
#
# Usage: sh claude/evals/run-triggers.sh <skill-name> [runs-per-query]
# Env:   EVAL_MODEL (default claude-sonnet-5), MAX_CALLS (default 3)
#
# Results print to stdout as JSON and are archived under
# claude/evals/results/ (gitignored) with the model and date pinned.

set -u

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
skill=${1:?usage: run-triggers.sh <skill-name> [runs-per-query]}
runs=${2:-2}
model=${EVAL_MODEL:-claude-sonnet-5}
max_calls=${MAX_CALLS:-3}

skill_dir=$repo_root/claude/plugin/skills/$skill
cases=$skill_dir/evals/trigger-evals.json
[ -f "$cases" ] || { echo "No trigger-evals.json for '$skill'" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cmdname="$skill-eval-$(date +%s)"

# Template fixture: a realistic repo state so queries aren't nonsensical —
# history, a feature branch, and an uncommitted change.
template=$work/template
mkdir -p "$template" && cd "$template"
git init -q .
printf '# demo\n' > README.md
printf 'def add(a, b):\n    return a + b\n' > app.py
git add -A && git commit -qm "chore: initial project"
git checkout -qb feature/retry-logic
printf 'def retry(fn):\n    return fn()\n' > retry.py
git add retry.py && git commit -qm "feat: add retry helper"
printf 'def add(a, b):\n    return a + b  # tweaked\n' > app.py

# Inject the skill's description as a command file (skill-creator's trick),
# reusing the SKILL.md frontmatter verbatim minus its name line.
mkdir -p "$template/.claude/commands"
{
  printf -- '---\n'
  awk 'f && /^---$/{exit} f{print} /^---$/{f=1}' "$skill_dir/SKILL.md" | grep -v '^name:'
  printf -- '---\n\n# %s\n\nConsult this skill for the tasks its description covers.\n' "$cmdname"
} > "$template/.claude/commands/$cmdname.md"

# One run: spawn claude -p in a private copy of the fixture, then score the
# stream: was the Skill tool invoked with our name within the first K calls?
run_one() {
  q=$1; i=$2; r=$3
  fixture=$work/fix-$i-$r
  cp -R "$template" "$fixture"
  out=$work/stream-$i-$r.jsonl
  ( cd "$fixture" && CLAUDECODE= claude -p "$q" \
      --output-format stream-json --verbose \
      --max-turns 3 --model "$model" > "$out" 2>/dev/null ) || true
  jq -s --arg name "$cmdname" --argjson k "$max_calls" '
    [ .[] | select(.type == "assistant")
      | .message.content[]? | select(.type == "tool_use") ]
    | .[0:$k]
    | map(select(.name == "Skill") | .input.skill // "")
    | any(contains($name))
  ' < "$out" > "$work/verdict-$i-$r" 2>/dev/null || echo false > "$work/verdict-$i-$r"
}

# Fan out with a crude concurrency cap of 4.
total_queries=$(jq 'length' "$cases")
i=0; active=0
while [ "$i" -lt "$total_queries" ]; do
  q=$(jq -r ".[$i].query" "$cases")
  r=1
  while [ "$r" -le "$runs" ]; do
    run_one "$q" "$i" "$r" &
    active=$((active + 1))
    if [ "$active" -ge 4 ]; then wait; active=0; fi
    r=$((r + 1))
  done
  i=$((i + 1))
done
wait

# Aggregate per query: trigger rate vs expectation (threshold 0.5).
i=0
while [ "$i" -lt "$total_queries" ]; do
  triggers=0; r=1
  while [ "$r" -le "$runs" ]; do
    [ "$(cat "$work/verdict-$i-$r")" = "true" ] && triggers=$((triggers + 1))
    r=$((r + 1))
  done
  jq -cn --arg q "$(jq -r ".[$i].query" "$cases")" \
        --argjson exp "$(jq ".[$i].should_trigger" "$cases")" \
        --argjson t "$triggers" --argjson n "$runs" '
    {query: $q, should_trigger: $exp,
     trigger_rate: (($t / $n) * 100 | round / 100), triggers: $t, runs: $n,
     pass: (if $exp then ($t / $n) >= 0.5 else ($t / $n) < 0.5 end)}
  ' >> "$work/rows.ndjson"
  i=$((i + 1))
done

results_dir=$repo_root/claude/evals/results
mkdir -p "$results_dir"
outfile=$results_dir/triggers-$skill-$(date +%Y%m%d-%H%M%S).json
jq -s --arg skill "$skill" --arg model "$model" \
      --argjson k "$max_calls" --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  {skill: $skill, model: $model, max_calls: $k, run_at: $date, results: .,
   summary: {total: length,
             passed: ([.[] | select(.pass)] | length),
             failed: ([.[] | select(.pass | not)] | length)}}
' "$work/rows.ndjson" | tee "$outfile"
echo "archived: $outfile" >&2
