#!/bin/sh
set -u

here=$(cd "$(dirname "$0")" && pwd)
. "$here/utils.sh"

passed=0

test_case() {
  name="$1"
  shift
  if ( "$@" ) >/dev/null 2>&1; then
    echo "ok    $name"
    passed=$((passed + 1))
  else
    echo "FAIL  $name" >&2
    exit 1
  fi
}

test_case_fails() {
  name="$1"
  shift
  if ( "$@" ) >/dev/null 2>&1; then
    echo "FAIL  $name" >&2
    exit 1
  else
    echo "ok    $name"
    passed=$((passed + 1))
  fi
}

pkg_manager=""

test_case "ensure_package succeeds when the command exists" \
  ensure_package sh
test_case "ensure_package no-ops when pkg_manager is empty" \
  ensure_package definitely-not-a-dotfiles-command

test_case "jq is available for merge_json tests" \
  type jq

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

dest="$scratch/home/settings.json"
src="$scratch/repo/settings.json"
mkdir -p "$scratch/home" "$scratch/repo"
printf '%s\n' '{"theme":"dark","packages":["old"]}' > "$dest"
printf '%s\n' '{"packages":["new"]}' > "$src"
merge_json "$dest" "$src"
test_case "merge_json lets src keys win and keeps dest-only keys" \
  [ "$(jq -c . "$dest")" = '{"theme":"dark","packages":["new"]}' ]

empty="$scratch/home/empty.json"
printf '%s\n' '{"enabled":true}' > "$src"
merge_json "$empty" "$src"
test_case "merge_json starts an empty dest as {}" \
  [ "$(jq -c . "$empty")" = '{"enabled":true}' ]

test_case "tomlq is available for merge_toml tests" \
  type tomlq

toml_dest="$scratch/home/config.toml"
toml_src="$scratch/repo/config.toml"
printf '%s\n' 'model = "gpt-test"

[plugins."gmail@openai-curated"]
enabled = true' > "$toml_dest"
printf '%s\n' '[plugins."zabrabot@zabrador"]
enabled = true' > "$toml_src"
merge_toml "$toml_dest" "$toml_src"
test_case "merge_toml lets src keys win and keeps dest-only keys" \
  [ "$(tomlq -c . "$toml_dest")" = '{"model":"gpt-test","plugins":{"gmail@openai-curated":{"enabled":true},"zabrabot@zabrador":{"enabled":true}}}' ]

toml_empty="$scratch/home/empty.toml"
merge_toml "$toml_empty" "$toml_src"
test_case "merge_toml starts an empty dest as the src document" \
  [ "$(tomlq -c . "$toml_empty")" = '{"plugins":{"zabrabot@zabrador":{"enabled":true}}}' ]

test_case "run_if_present skips a missing command" \
  run_if_present "missing tool" definitely-not-a-dotfiles-command
test_case "run_if_present succeeds when the command succeeds" \
  run_if_present "true" true
test_case_fails "run_if_present exits when the command fails" \
  run_if_present "false" false

echo "$passed passed"
