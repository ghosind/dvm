#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh

# set active version to other.
dvm use v1.45.0
dvm ls | grep "\-> v1.45.0" || dvm_test_error "active version should be v1.45.0"

# set alias
dvm alias default v1.40.0 || dvm_test_error "run 'dvm alias default v1.40.0' failed"

# activate with alias name
dvm use default || dvm_test_error "run 'dvm use default' failed"

dvm ls | grep "\-> v1.40.0" || dvm_test_error "active version should be v1.40.0"
