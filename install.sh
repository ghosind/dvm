#!/usr/bin/env bash
# Installation script for Deno Version Manager
# Copyright (C) 2020 ~ 2023, Chen Su and all contributors.

# Ensure the script is downloaded completely
{

dvm_compare_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
}

dvm_has() {
  command -v "$1" > /dev/null
}

dvm_get_profile_file() {
  case ${SHELL##*/} in
  bash)
    DVM_PROFILE_FILE="$HOME/.bashrc"
    ;;
  zsh)
    DVM_PROFILE_FILE="$HOME/.zshrc"
    ;;
  *)
    DVM_PROFILE_FILE="$HOME/.profile"
    ;;
  esac
}

dvm_add_into_profile_file() {
  local is_dvm_defined

  dvm_get_profile_file

  is_dvm_defined=$(grep DVM_DIR < "$DVM_PROFILE_FILE")

  if [ -n "$is_dvm_defined" ]
  then
    return
  fi

  echo "
# Deno Version Manager
export DVM_DIR=\"\$HOME/.dvm\"
[ -f \"\$DVM_DIR/dvm.sh\" ] && . \"\$DVM_DIR/dvm.sh\"
[ -f \"\$DVM_DIR/bash_completion\" ] && . \"\$DVM_DIR/bash_completion\"
" >> "$DVM_PROFILE_FILE"
}

dvm_get_latest_version() {
  local request_url
  local response

  case "$DVM_SOURCE" in
  gitee)
    request_url="https://gitee.com/api/v5/repos/ghosind/dvm/releases/latest"
    ;;
  github|*)
    request_url="https://api.github.com/repos/ghosind/dvm/releases/latest"
    ;;
  esac

  if ! dvm_has curl
  then
    echo "curl is required."
    exit 1
  fi

  if ! response=$(curl -s "$request_url")
  then
    echo "Failed to get the latest DVM version."
    exit 1
  fi

  DVM_LATEST_VERSION=$(echo "$response" | sed 's/"/\n/g' | grep tag_name -A 2 | grep v)
}

dvm_install_latest_version() {
  local git_url
  local cmd

  case "$DVM_SOURCE" in
  gitee)
    git_url="https://gitee.com/ghosind/dvm.git"
    ;;
  github|*)
    git_url="https://github.com/ghosind/dvm.git"
    ;;
  esac

  if ! dvm_has git
  then
    echo "git is require."
    exit 1
  fi

  cmd="git clone -b $DVM_LATEST_VERSION $git_url $DVM_DIR --depth=1"

  if ! ${cmd}
  then
    echo "failed to download DVM."
    exit 1
  fi
}

set_dvm_dir() {
  if [ ! -d "$DVM_DIR" ]
  then
    mkdir -p "$DVM_DIR"
  else
    echo "directory $DVM_DIR already exists."
    exit 1
  fi
}

dvm_install() {
  set_dvm_dir

  DVM_SCRIPT_DIR=${0%/*}

  if [ -f "$DVM_SCRIPT_DIR/dvm.sh" ] &&
    [ -d "$DVM_SCRIPT_DIR/.git" ] &&
    [ -f "$DVM_SCRIPT_DIR/bash_completion" ]
  then
    # Copy all files to DVM_DIR
    cp -R "$DVM_SCRIPT_DIR/". "$DVM_DIR"
  else
    dvm_get_latest_version
    dvm_install_latest_version
  fi

  dvm_add_into_profile_file

  echo "DVM has been installed, please restart your terminal or run \`source $DVM_PROFILE_FILE\` to apply changes."
}

dvm_set_default() {
  DVM_DIR=${DVM_DIR:-$HOME/.dvm}
  DVM_SOURCE=${DVM_SOURCE:-github}
}

dvm_print_help() {
  printf "DVM install script

Usage: install.sh [-r <github|gitee>] [-d <dvm_dir>]

Options:
  -r <github|gitee>   Set the repository server, default github.
  -d dir              Set the dvm install directory, default ~/.dvm.
  -h                  Print help.

Example:
  install.sh -r github -d ~/.dvm
"
}

dvm_set_default

while getopts "hr:d:" opt
do
  case "$opt" in
  h)
    dvm_print_help
    exit 0
    ;;
  r)
    if [ "$OPTARG" != "github" ] && [ "$OPTARG" != "gitee" ]
    then
      dvm_print_help
      exit 1
    fi
    DVM_SOURCE="$OPTARG"
    ;;
  d)
    if [ -z "$OPTARG" ]
    then
      dvm_print_help
      exit 1
    fi

    DVM_DIR="$OPTARG"
    ;;
  *)
    ;;
  esac
done

if [ "$DVM_SOURCE" != "github" ] && [ "$DVM_SOURCE" != "gitee" ]
then
  dvm_print_help
  exit 1
fi

dvm_install

}
