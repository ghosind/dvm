#!/usr/bin/env bash

get_rc_file() {
  shell=${SHELL##*/}

  if [ "$shell" == "bash" ]
  then
    rc_file="$HOME/.bashrc"
  elif [ "$shell" == "zsh" ]
  then
    rc_file="$HOME/.zshrc"
  else
    rc_file="$HOME/.profile"
  fi
}

add_nvm_into_rc_file() {
  get_rc_file

  echo "
# Deno Version Manager
export DVM_DIR=\"\$HOME/.dvm\"
export DVM_BIN=\"\$DVM_DIR/bin\"
export PATH=\"\$PATH:\$DVM_BIN\"
[ -f \"\$DVM_DIR/dvm.sh\" ] && alias dvm=\"\$DVM_DIR/dvm.sh\"
" >> "$rc_file"
}

get_latest_version() {
  local request_url

  request_url="https://api.github.com/repos/ghosind/dvm/releases/latest"

  DVM_LATEST_VERSION=$(curl "$request_url" 2>/dev/null | grep tag_name | cut -d '"' -f 4)
}

download_latest_version() {
  DVM_TMP_DIR=$(mktemp -d -t dvm)

  curl -LJ "https://github.com/ghosind/dvm/archive/$DVM_LATEST_VERSION.tar.gz" \
      -o "$DVM_TMP_DIR/dvm.tar.gz"
}

install_latest_version() {
  local version
  version=$(echo "$DVM_LATEST_VERSION" | cut -d "v" -f 2)

  tar -xzvf "$DVM_TMP_DIR/dvm.tar.gz" -C "$DVM_TMP_DIR"
  # shellcheck disable=SC2086
  mv $DVM_TMP_DIR/dvm-$version/* "$DVM_DIR"
}

set_dvm_dir() {
  DVM_DIR="$HOME/.dvm"

  if [ ! -d "$DVM_DIR" ]
  then
    mkdir -p "$DVM_DIR"
  fi
}

install_dvm() {
  set -e

  set_dvm_dir

  get_latest_version
  download_latest_version
  install_latest_version

  add_nvm_into_rc_file
}

install_dvm
