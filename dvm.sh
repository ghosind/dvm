#!/usr/bin/env bash

get_arch() {
  if [ "$(uname -m)" != 'x86_64' ]
  then
    echo 'Only x64 binaries are supported.'
    exit 1
  fi

  case $(uname -s) in
  Darwin)
    DVM_ARCH='x86_64-apple-darwin'
    ;;
  Linux)
    DVM_ARCH='x86_64-unknown-linux-gnu'
    ;;
  *)
    echo "Unsupported architecture $(uname -s)"
  esac
}

check_local_version() {
  if [ ! -d "$DVM_DIR/versions/$1" ]
  then
    return
  fi

  if [ -f "$DVM_DIR/versions/$1/deno" ]
  then
    echo "deno $1 has been installed"
    exit 1
  fi
}

install_version() {
  check_local_version "$1"
  get_arch

  DVM_TMP_DIR=$(mktemp -d -t dvm)

  remote_url="https://github.com/denoland/deno/releases/download/$1/deno-$DVM_ARCH.zip"

  curl -LJ "$remote_url" -o "$DVM_TMP_DIR/deno-$1.zip"

  target_dir="$DVM_DIR/versions/$1"

  if [ ! -d "$target_dir" ]
  then
    mkdir "$target_dir"
  fi

  unzip -f "$DVM_TMP_DIR/deno-$1.zip" -d "$target_dir"
}

set -e

DVM_DIR="$HOME/.dvm"

case $1 in
install)
  if [ -z "$2" ]
  then
    echo "Must specify target version"
    exit 1
  fi
  install_version "$2"
  ;;
# uninstall)
#   # uninstall the specified version
#   ;;
# list | ls)
#   # list all local versions
#   ;;
# list-remote | ls-remote)
#   # list all remote versions
#   ;;
# current)
#   # get the current version
#   ;;
# use)
#   # change current version to specified version
#   ;;
*)
  echo "Unknown command $1"
  exit 1
  ;;
esac
