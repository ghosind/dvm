#!/usr/bin/env bash

# DVM Installation Script (Deno Version Manager)
# Copyright (C) 2020 ~ 2025, Chen Su and all contributors.

## Ensure the script is fully downloaded before running
{

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

dvm_check_dir() {
  if [ ! -d "$DVM_DIR" ]
  then
    mkdir -p "$DVM_DIR"
  else
    echo "Directory $DVM_DIR already exists."
    exit 1
  fi
}

dvm_compare_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
}

dvm_get_latest_version() {
  local request_url
  local response

  case "$DVM_SOURCE" in
  "gitee")
    request_url="https://gitee.com/api/v5/repos/ghosind/dvm/releases/latest"
    ;;
  "github"|*)
    request_url="https://api.github.com/repos/ghosind/dvm/releases/latest"
    ;;
  esac

  if ! dvm_has curl
  then
    echo "Error: curl is required."
    exit 1
  fi

  if ! response=$(curl -s "$request_url")
  then
    echo "Error: Failed to retrieve the latest DVM version."
    exit 1
  fi

  DVM_LATEST_VERSION=$(echo "$response" | sed 's/"/\n/g' | grep tag_name -A 2 | grep v)
}

dvm_get_profile_file() {
  case "${SHELL##*/}" in
  "bash")
    DVM_PROFILE_FILE="$HOME/.bashrc"
    ;;
  "zsh")
    DVM_PROFILE_FILE="$HOME/.zshrc"
    ;;
  *)
    DVM_PROFILE_FILE="$HOME/.profile"
    ;;
  esac
}

dvm_has() {
  command -v "$1" > /dev/null
}

dvm_install() {
  dvm_check_dir

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

  echo "DVM has been installed. Please restart your terminal or run \`source $DVM_PROFILE_FILE\` to apply the changes."
}

dvm_install_latest_version() {
  local git_url
  local cmd

  case "$DVM_SOURCE" in
  "gitee")
    git_url="https://gitee.com/ghosind/dvm.git"
    ;;
  "github"|*)
    git_url="https://github.com/ghosind/dvm.git"
    ;;
  esac

  if ! dvm_has git
  then
    echo "Error: git is required."
    exit 1
  fi

  cmd="git clone -b $DVM_LATEST_VERSION $git_url $DVM_DIR --depth=1"

  if ! ${cmd}
  then
    echo "Error: Failed to download DVM."
    exit 1
  fi
}

dvm_print_help() {
  echo "DVM Installation Script"
  echo
  echo "Usage: install.sh [-r <github|gitee>] [-d <dvm_dir>]"
  echo
  echo "Options:"
  echo "  -r <github|gitee>   Specify the repository server (default: github)."
  echo "  -d <dir>           Specify the DVM installation directory (default: ~/.dvm)."
  echo "  -h                  Show this help message."
  echo
  echo "Example:"
  echo "  install.sh -r github -d ~/.dvm"
}

dvm_set_default() {
  DVM_DIR=${DVM_DIR:-$HOME/.dvm}
  DVM_SOURCE=${DVM_SOURCE:-github}
}

dvm_set_default

while getopts "hr:d:" opt
do
  case "$opt" in
  "h")
    dvm_print_help
    exit 0
    ;;
  "r")
    if [ "$OPTARG" != "github" ] && [ "$OPTARG" != "gitee" ]
    then
      dvm_print_help
      exit 1
    fi
    DVM_SOURCE="$OPTARG"
    ;;
  "d")
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
