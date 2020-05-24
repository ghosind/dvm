#!/usr/bin/env bash

if [ -f "$DVM_DIR/.current" ]
then
  current_version=$(cat "$DVM_DIR/.current")
fi

if [ -n "$current_version" ] && [ -f "$DVM_DIR/versions/$current_version/deno" ]
then
  export DVM_BIN="$DVM_DIR/version/$current_version"
  export PATH="$PATH:$DVM_DIR"
else
  export DVM_BIN=""
fi
