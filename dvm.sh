#!/usr/bin/env bash

get_package_name() {
  if [ "$(uname -m)" != 'x86_64' ]
  then
    echo 'Only x64 binaries are supported.'
    exit 1
  fi

  case $(uname -s) in
  Darwin)
    target_name='deno-x86_64-apple-darwin.zip'
    ;;
  Linux)
    target_name='deno-x86_64-unknown-linux-gnu.zip'
    ;;
  *)
    echo "Unsupported architecture $(uname -s)"
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
    wget "https://github.com/denoland/deno/releases/download/$1/$target_name" \
      -O "$DVM_DIR/download/$1/deno-downloading.zip"
  else
    curl -LJ "https://github.com/denoland/deno/releases/download/$1/$target_name" \
      -o "$DVM_DIR/download/$1/deno-downloading.zip"
  fi

  if [ ! -x "$?" ]
  then
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
