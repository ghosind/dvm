#!/usr/bin/env bash

compare_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
}

get_package_name() {
  if [ "$(uname -m)" != 'x86_64' ]
  then
    echo 'Only x64 binaries are supported.'
    exit 1
  fi

  local host_os
  local min_version

  host_os=$(uname -s)
  min_version="v0.36.0"

  case $host_os in
  Darwin)
    if compare_version "$1" "$min_version"
    then
      DVM_TARGET_NAME='deno_osx_x64.gz'
      return
    fi
    DVM_TARGET_NAME='deno-x86_64-apple-darwin.zip'
    ;;
  Linux)
    if compare_version "$1" "$min_version"
    then
      DVM_TARGET_NAME='deno_linux_x64.gz'
      return
    fi
    DVM_TARGET_NAME='deno-x86_64-unknown-linux-gnu.zip'
    ;;
  *)
    echo "Unsupported operating system $host_os"
  esac
}

download_file() {
  if [ ! -d "$DVM_DIR/download/$1" ]
  then
    mkdir -p "$DVM_DIR/download/$1"
  fi

  get_package_name "$1"

  if [ -x "$(command -v wget)" ]
  then
    wget "https://github.com/denoland/deno/releases/download/$1/$DVM_TARGET_NAME" \
      -O "$DVM_DIR/download/$1/deno-downloading.zip"
  else
    curl -LJ "https://github.com/denoland/deno/releases/download/$1/$DVM_TARGET_NAME" \
      -o "$DVM_DIR/download/$1/deno-downloading.zip"
  fi

  if [ ! -x "$?" ]
  then
    local file_type
    file_type=$(file "$DVM_DIR/download/$1/deno-downloading.zip")

    if [[ $file_type == *"Zip"* ]]
    then
      mv "$DVM_DIR/download/$1/deno-downloading.zip" "$DVM_DIR/download/$1/deno.zip"
      return
    fi
  fi

  rm "$DVM_DIR/download/$1/deno-downloading.zip"
  echo "Failed to download."
  exit 1
}

extract_file() {
  target_dir="$DVM_DIR/versions/$1"

  if [ ! -d "$target_dir" ]
  then
    mkdir -p "$target_dir"
  fi

  unzip "$DVM_DIR/download/$1/deno.zip" -d "$target_dir" > /dev/null
}

check_local_version() {
  if [ ! -d "$DVM_DIR/versions/$1" ]
  then
    return
  fi

  if [ -f "$DVM_DIR/versions/$1/deno" ]
  then
    echo "deno $1 has been installed."
    exit 1
  fi
}

install_version() {
  check_local_version "$1"
  download_file "$1"
  extract_file "$1"

  echo "deno $1 has installed."
}

uninstall_version() {
  if [ -f "$DVM_DIR/versions/$1/deno" ]
  then
    rm -rf "$DVM_DIR/versions/$1"
  fi
}

list_local_versions() {
  # shellcheck disable=SC2012
  ls "$DVM_DIR/versions" | while read -r dir
  do
    if [ -f $"$DVM_DIR/versions/$dir/deno" ]
    then
      echo "$dir"
    fi
  done
}

check_dvm_dir() {
  if [ -z "$DVM_DIR" ]
  then
    # set default dvm directory
    DVM_DIR="$HOME/.dvm"
  fi
}

dvm() {
  case $1 in
  install)
    if [ -z "$2" ]
    then
      echo "Must specify target version"
      exit 1
    fi
    install_version "$2"
    ;;
  uninstall)
    # uninstall the specified version
    if [ -z "$2" ]
    then
      echo "Must specify target version"
      exit 1
    fi

    uninstall_version "$2"
    ;;
  list | ls)
    # list all local versions

    list_local_versions
    ;;
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
}

set -e

check_dvm_dir

dvm "$@"
