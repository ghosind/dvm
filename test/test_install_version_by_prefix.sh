#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh || dvm_test_error "failed to install dvm"

# Install deno by prefix
dvm install 1.44 || dvm_test_error "run 'dvm install 1.44' failed"
dvm ls | grep "v1.44.4" || dvm_test_error "run 'dvm ls' failed"

# Skip if run on MacOS with m-chip
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]
then
  if dvm install 1.2
  then
    dvm_test_error "Deno v1.2 should not be installed on MacOS with m-chip"
  fi
else
  dvm install 1.2 || dvm_test_error "run 'dvm install 1.2' failed"
  dvm ls | grep "v1.2.3" || dvm_test_error "run 'dvm ls' failed"
fi
