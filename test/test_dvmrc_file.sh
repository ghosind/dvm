#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh || dvm_test_error "failed to install dvm"

echo "v1.45.0" > .dvmrc
dvm use || dvm_test_error "run 'dvm use' failed"
dvm ls | grep "\-> v1.45.0" || dvm_test_error "run 'dvm ls' failed"
rm .dvmrc

echo "v1.40.0" > .deno-version
dvm use || dvm_test_error "run 'dvm use' failed"
dvm ls | grep "\-> v1.40.0" || dvm_test_error "run 'dvm ls' failed"
rm .deno-version

echo "v1.44.4" > "$HOME/.dvmrc"
dvm use || dvm_test_error "run 'dvm use' failed"
dvm ls | grep "\-> v1.44.4" || dvm_test_error "run 'dvm ls' failed"
rm "$HOME/.dvmrc"
