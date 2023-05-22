#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh || dvm_test_error "failed to install dvm"

versions=$(dvm ls-remote)

[ "$(echo "$versions" | grep v0.1.0)" = "" ] || dvm_test_error "Deno v0.1.0 should in the remote versions list"

# Not same page
[ "$(echo "$versions" | grep v1.33.0)" = "" ] || dvm_test_error "Deno v1.33.0 should in the remote versions list"
