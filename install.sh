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
export DVM_DIR=\"$HOME/.dvm\"
[ -f \"$DVM_DIR/dvm.sh\" ] && alias dvm=\"\$DVM_DIR/dvm.sh\"
  " >> "$rc_file"
}

add_nvm_into_rc_file
