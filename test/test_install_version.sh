#!/bin/bash

dvm_error() {
  echo "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh || dvm_error "[ERR] failed to install dvm"

# Install deno v1.0.0
TARGET_VERSION="1.0.0"
dvm install "v$TARGET_VERSION" || dvm_error "[ERR] 'dvm install v$TARGET_VERSION' failed"

# Check installed version directory
[ -d "$DVM_DIR/versions/v$TARGET_VERSION" ] || dvm_error "[ERR] '$DVM_DIR/versions/v$TARGET_VERSION' is not a directory"

# Check deno version
dvm run "v$TARGET_VERSION" --version | grep "deno $TARGET_VERSION" || dvm_error "[ERR] deno is invalid"

# Set active version
dvm use "v$TARGET_VERSION" || dvm_error "[ERR] 'dvm use v$TARGET_VERSION' failed"

# Check with ls command
dvm ls | grep "\-> v$TARGET_VERSION" || dvm_error "[ERR] 'dvm ls' failed"
