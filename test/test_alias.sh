#!/bin/bash

dvm_error() {
  echo "$@"
  exit 1
}

# shellcheck disable=SC1091
\. ./dvm.sh

# set active version to other.
dvm use v1.14.0
dvm ls | grep "\-> v1.14.0" || dvm_error "[ERR] active version should be v1.14.0"

# set alias
dvm alias default v1.0.0 || dvm_error "[ERR] 'dvm alias default v1.0.0' failed"

# activate with alias name
dvm use default || dvm_error "[ERR] 'dvm use default' failed"

dvm ls | grep "\-> v1.0.0" || dvm_error "[ERR] active version should be v1.0.0"
