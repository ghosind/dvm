#!/bin/bash

dvm_test_error() {
  echo "[ERR]" "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh

# Set alias name 'default' to v1.14.0
dvm alias default v1.14.0 --verbose || dvm_test_error "run 'dvm alias default v1.14.0' failed"

# Uninstall by alias name
dvm uninstall default --verbose || dvm_test_error "run 'dvm uninstall default' failed"
[ ! -f "$DVM_DIR/versions/v1.14.0/deno" ] || dvm_test_error "deno v1.14.0 should be uninstalled"

# Install deno v1.14.0 again
dvm install v1.14.0 --verbose

dvm deactivate

# Uninstall by version
dvm uninstall v1.14.0 --verbose || dvm_test_error "run 'dvm uninstall v1.14.0' failed"
[ ! -f "$DVM_DIR/versions/v1.14.0/deno" ] || dvm_test_error "deno v1.14.0 should be uninstalled"
