#!/bin/bash

dvm_error() {
  echo "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh || dvm_error "[ERR] failed to install dvm"

TARGET_VERSION="1.0.0"

# Install deno
dvm install "v$TARGET_VERSION" || dvm_error "[ERR] 'dvm install v$TARGET_VERSION' failed"

# Check installed version directory
[ -d "$DVM_DIR/versions/v$TARGET_VERSION" ] || dvm_error "[ERR] '$DVM_DIR/versions/v$TARGET_VERSION' is not a directory"

# Check deno version
dvm run "v$TARGET_VERSION" --version | grep "deno $TARGET_VERSION" || dvm_error "[ERR] deno is invalid"
