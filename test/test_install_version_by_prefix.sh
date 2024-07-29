#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# Install deno by prefix
dvm install 1.44 || dvm_test_error "run 'dvm install 1.44' failed"
dvm ls | grep "v1.44.4" || dvm_test_error "run 'dvm ls' failed"

if [ "$(uname -s)" = "Linux" ]
then
  dvm install 1.2 || dvm_test_error "run 'dvm install 1.2' failed"
  dvm ls | grep "v1.2.3" || dvm_test_error "run 'dvm ls' failed"
fi
