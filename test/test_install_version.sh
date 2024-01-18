#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh || dvm_test_error "failed to install dvm"

# Install deno v1.0.0
TARGET_VERSION="1.0.0"
dvm install "v$TARGET_VERSION" --verbose || dvm_test_error "run 'dvm install v$TARGET_VERSION' failed"

# Check installed version directory
[ -d "$DVM_DIR/versions/v$TARGET_VERSION" ] || dvm_test_error "'$DVM_DIR/versions/v$TARGET_VERSION' is not a directory"

# Install another deno
dvm install v1.14.0 --verbose

# Check deno version
dvm run "v$TARGET_VERSION" --version | grep "deno $TARGET_VERSION" || dvm_test_error "deno is invalid"

# Set active version
dvm use "v$TARGET_VERSION" --verbose || dvm_test_error "run 'dvm use v$TARGET_VERSION' failed"

# Check with ls command
dvm ls | grep "\-> v$TARGET_VERSION" || dvm_test_error "run 'dvm ls' failed"
