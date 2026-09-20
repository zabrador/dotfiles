#!/bin/sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
. "$here/utils.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pkg_manager=""
if ! ensure_package sh; then
  fail "ensure_package should succeed when the command exists"
fi
if ! ensure_package definitely-not-a-dotfiles-command; then
  fail "ensure_package should no-op when pkg_manager is empty"
fi

if ! type jq > /dev/null 2>&1; then
  fail "jq is required to test merge_json"
fi

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

dest="$scratch/home/settings.json"
src="$scratch/repo/settings.json"
mkdir -p "$scratch/home" "$scratch/repo"
printf '%s\n' '{"theme":"dark","packages":["old"]}' > "$dest"
printf '%s\n' '{"packages":["new"]}' > "$src"
merge_json "$dest" "$src"
got=$(jq -c . "$dest")
[ "$got" = '{"theme":"dark","packages":["new"]}' ] || fail "merge_json should let src keys win and keep dest-only keys (got $got)"

empty="$scratch/home/empty.json"
printf '%s\n' '{"enabled":true}' > "$src"
merge_json "$empty" "$src"
got=$(jq -c . "$empty")
[ "$got" = '{"enabled":true}' ] || fail "merge_json should start an empty dest as {} (got $got)"

if ! run_if_present "missing tool" definitely-not-a-dotfiles-command; then
  fail "run_if_present should skip a missing command"
fi

if ! run_if_present "true" true; then
  fail "run_if_present should succeed when the command succeeds"
fi

if (run_if_present "false" false); then
  fail "run_if_present should exit when the command fails"
fi

echo "ok"
