#!/bin/sh
# Behavioral evals: run each evals.json case end-to-end and grade the result.
#
# For each case, two claude -p sessions run in a scratch workspace:
#   1. Executor - performs the case's task with the skill's instructions
#      explicitly in hand (behavioral evals test doctrine-following, not
#      routing; routing is run-triggers.sh's job).
#   2. Grader - inspects the resulting workspace (git log/show, files) plus
#      the executor's report, and judges each expectation with evidence.
#
# Usage: sh claude/evals/run-behavioral.sh <skill-name>
# Env:   EVAL_MODEL (default claude-sonnet-5)
#
# Results print to stdout as JSON and archive under claude/evals/results/
# (gitignored) with the model and date pinned.

set -u

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
skill=${1:?usage: run-behavioral.sh <skill-name>}
model=${EVAL_MODEL:-claude-sonnet-5}

skill_dir=$repo_root/claude/plugin/skills/$skill
cases=$skill_dir/evals/evals.json
[ -f "$cases" ] || { echo "No evals.json for '$skill'" >&2; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

run_case() {
  i=$1
  prompt=$(jq -r ".evals[$i].prompt" "$cases")
  expectations=$(jq -c ".evals[$i].expectations" "$cases")
  ws=$work/case-$i
  mkdir -p "$ws"

  # The pre-approval sentence matters: machine policy may (correctly) require
  # explicit user confirmation before commits, and no user exists in a
  # headless session. Running this eval suite IS the user's confirmation for
  # commits inside the disposable workspace.
  ( cd "$ws" && CLAUDECODE= claude -p \
      "Read the skill instructions at $skill_dir/SKILL.md and follow them where they apply. Then complete this task in the current directory: $prompt --- This is a disposable eval workspace: the user running this eval has explicitly pre-approved creating git repositories and commits here, so proceed without pausing for confirmation." \
      --output-format json --max-turns 25 --model "$model" \
      --allowedTools 'Bash,Read,Write,Edit,Glob,Grep' \
      --add-dir "$skill_dir" > "$work/exec-$i.json" 2>/dev/null ) || true
  report=$(jq -r '.result // "the executor produced no final report"' "$work/exec-$i.json" 2>/dev/null | head -c 3000)

  ( cd "$ws" && CLAUDECODE= claude -p \
      "You are grading the outcome of a task another agent performed in this directory. Do not redo, fix, or change anything - only inspect (git log, git show, file contents) and judge. The task given was: <task>$prompt</task> The executor's final report was: <report>$report</report> Grade each of these expectations against what you find: $expectations. Respond with ONLY a JSON object, no prose and no code fences: {\"expectations\":[{\"text\":\"...\",\"passed\":true,\"evidence\":\"...\"}]} - one entry per expectation, evidence citing exactly what you inspected." \
      --output-format json --max-turns 15 --model "$model" \
      --allowedTools 'Bash,Read,Glob,Grep' > "$work/grade-$i.json" 2>/dev/null ) || true

  jq -c --argjson id "$(jq ".evals[$i].id" "$cases")" '
    ( .structured_output
      // (.result | gsub("```(json)?"; "") | fromjson?)
      // {expectations: []} ) as $g
    | {id: $id,
       passed: ([$g.expectations[]? | select(.passed)] | length),
       total: ($g.expectations | length),
       expectations: $g.expectations}
  ' "$work/grade-$i.json" > "$work/row-$i.json" 2>/dev/null \
    || printf '{"id":%s,"passed":0,"total":0,"expectations":[],"error":"grading failed"}\n' \
         "$(jq ".evals[$i].id" "$cases")" > "$work/row-$i.json"
}

# Fan out, at most 3 cases in flight (each case is two model sessions).
n=$(jq '.evals | length' "$cases")
i=0; active=0
while [ "$i" -lt "$n" ]; do
  run_case "$i" &
  active=$((active + 1))
  if [ "$active" -ge 3 ]; then wait; active=0; fi
  i=$((i + 1))
done
wait

results_dir=$repo_root/claude/evals/results
mkdir -p "$results_dir"
outfile=$results_dir/behavioral-$skill-$(date +%Y%m%d-%H%M%S).json
jq -s --arg skill "$skill" --arg model "$model" \
      --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
  {skill: $skill, model: $model, run_at: $date, cases: .,
   summary: {cases: length,
             expectations_passed: ([.[].passed] | add // 0),
             expectations_total: ([.[].total] | add // 0),
             pass_rate: (if ([.[].total] | add // 0) > 0
                         then (([.[].passed] | add) / ([.[].total] | add) * 100 | round / 100)
                         else 0 end)}}
' "$work"/row-*.json | tee "$outfile"
echo "archived: $outfile" >&2
