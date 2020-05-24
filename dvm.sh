#!/usr/bin/env bash

compare_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
}

get_package_data() {
  if [ "$(uname -m)" != 'x86_64' ]
  then
    echo 'Only x64 binaries are supported.'
    exit 1
  fi

  local host_os
  local min_version

  host_os=$(uname -s)
  min_version="v0.36.0"

  if compare_version "$1" "$min_version"
  then
    case $host_os in
    "Darwin")
      DVM_TARGET_NAME='deno_osx_x64.gz'
      ;;
    "Linux")
      DVM_TARGET_NAME='deno_linux_x64.gz'
      ;;
    *)
      echo "Unsupported operating system $host_os"
      ;;
    esac
    DVM_TARGET_TYPE="gz"
    DVM_FILE_TYPE="gzip compressed data"
  else
    case $host_os in
    "Darwin")
      DVM_TARGET_NAME='deno-x86_64-apple-darwin.zip'
      ;;
    "Linux")
      DVM_TARGET_NAME='deno-x86_64-unknown-linux-gnu.zip'
      ;;
    *)
      echo "Unsupported operating system $host_os"
      ;;
    esac
    DVM_TARGET_TYPE="zip"
    DVM_FILE_TYPE="Zip archive data"
  fi
}

download_file() {
  if [ ! -d "$DVM_DIR/download/$1" ]
  then
    mkdir -p "$DVM_DIR/download/$1"
  fi

  if [ -x "$(command -v wget)" ]
  then
    wget "https://github.com/denoland/deno/releases/download/$1/$DVM_TARGET_NAME" \
      -O "$DVM_DIR/download/$1/deno-downloading.$DVM_TARGET_TYPE"
  else
    curl -LJ "https://github.com/denoland/deno/releases/download/$1/$DVM_TARGET_NAME" \
      -o "$DVM_DIR/download/$1/deno-downloading.$DVM_TARGET_TYPE"
  fi

  if [ ! -x "$?" ]
  then
    local file_type
    file_type=$(file "$DVM_DIR/download/$1/deno-downloading.$DVM_TARGET_TYPE")

    if [[ $file_type == *"$DVM_FILE_TYPE"* ]]
    then
      mv "$DVM_DIR/download/$1/deno-downloading.$DVM_TARGET_TYPE" \
        "$DVM_DIR/download/$1/deno.$DVM_TARGET_TYPE"
      return
    fi
  fi

  rm "$DVM_DIR/download/$1/deno-downloading.$DVM_TARGET_TYPE"
  echo "Failed to download."
  exit 1
}

extract_file() {
  target_dir="$DVM_DIR/versions/$1"

  if [ ! -d "$target_dir" ]
  then
    mkdir -p "$target_dir"
  fi

  case $DVM_TARGET_TYPE in
  "zip")
    unzip "$DVM_DIR/download/$1/deno.zip" -d "$target_dir" > /dev/null
    ;;
  "gz")
    gunzip -c "$DVM_DIR/download/$1/deno.gz" > "$target_dir/deno"
    chmod +x "$target_dir/deno"
    ;;
  *)
    ;;
  esac
}

install_version() {
  if [ -f "$DVM_DIR/versions/$1/deno" ]
  then
    echo "deno $1 has been installed."
    exit 1
  fi

  get_package_data "$1"

  if [ ! -f "$DVM_DIR/download/$1/deno.$DVM_TARGET_TYPE" ]
  then
    download_file "$1"
  fi

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
    if [ -f "$DVM_DIR/versions/$dir/deno" ]
    then
      echo "$dir"
    fi
  done
}

list_remote_versions() {
  local releases_url
  local all_versions
  local page
  local size
  local num

  page=1
  size=100
  num="$size"
  releases_url="https://api.github.com/repos/denoland/deno/releases?per_page=$size"
  
  while [ "$num" -eq "$size" ]
  do
    local versions
    versions=$(curl "$releases_url&page=$page" 2>/dev/null | grep tag_name | cut -d '"' -f 4)
    num=$(echo "$versions" | wc -l)
    page=$((page + 1))

    all_versions="$all_versions\n$versions"
  done

  echo -e "$all_versions"
}

check_dvm_dir() {
  if [ -z "$DVM_DIR" ]
  then
    # set default dvm directory
    DVM_DIR="$HOME/.dvm"
  fi
}

clean_download_cache() {
  # shellcheck disable=SC2012
  ls "$DVM_DIR/download" | while read -r dir
  do
    [ -f "$DVM_DIR/download/$dir/deno-downloading.zip" ] && \
      rm "$DVM_DIR/download/$dir/deno-downloading.zip"

    [ -f "$DVM_DIR/download/$dir/deno-downloading.gz" ] && \
      rm "$DVM_DIR/download/$dir/deno-downloading.gz"

    [ -f "$DVM_DIR/download/$dir/deno.zip" ] && \
      rm "$DVM_DIR/download/$dir/deno.zip"

    [ -f "$DVM_DIR/download/$dir/deno.gz" ] && \
      rm "$DVM_DIR/download/$dir/deno.gz"

    rmdir "$DVM_DIR/download/$dir"
  done
}

use_version() {
  if [ -f "$DVM_DIR/versions/$1/deno" ]
  then
    export DVM_BIN="$DVM_DIR/versions/$1"
    export PATH="$PATH:$DVM_BIN"
  else
    echo "deno $1 is not installed."
    exit 1
  fi
}

get_current_version() {
  if [ -z "$DVM_BIN" ] || [ ! -f "$DVM_BIN/deno" ]
  then
    echo "none"
    exit 1
  fi

  "$DVM_BIN/deno" --version | grep deno | cut -d " " -f 2
}

print_help() {
  printf "
Deno Version Manager

Usage:
  dvm install <version>       Download and install the specified version from source.
  dvm uninstall <version>     Uninstall a version.
  dvm use <version>           Modify PATH to use the specified version.
  dvm current                 Display the current version of Deno.
  dvm ls                      List all installed versions.
  dvm ls-remote               List all remote versions.
  dvm clean                   Remove all downloaded packages.

Examples:
  dvm install v1.0.0
  dvm uninstall v0.42.0
  dvm use v1.0.0

"
}

dvm() {
  check_dvm_dir

  case $1 in
  install)
    # install the specified version
    shift

    if [ -z "$1" ]
    then
      echo "Must specify target version"
      print_help
      exit 1
    fi

    install_version "$1"

    ;;
  uninstall)
    # uninstall the specified version
    shift

    if [ -z "$1" ]
    then
      echo "Must specify target version"
      print_help
      exit 1
    fi

    uninstall_version "$1"

    ;;
  list | ls)
    # list all local versions

    list_local_versions

    ;;
  list-remote | ls-remote)
    # list all remote versions
    list_remote_versions

    ;;
  current)
    # get the current version
    get_current_version

    ;;
  use)
    # change current version to specified version
    shift

    if [ -z "$1" ]
    then
      echo "Must specify target version."
      print_help
      exit 1
    fi

    use_version "$1"
    ;;
  clean)
    # remove all download packages.
    clean_download_cache
    ;;
  help)
    # print help
    print_help

    ;;
  *)
    echo "Unknown command $1"
    print_help

    exit 1
    ;;
  esac
}

dvm "$@"
