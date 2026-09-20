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

echo "ok"
