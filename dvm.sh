#!/usr/bin/env bash

DVM_VERSION="v0.2.1"

compare_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
}

get_package_data() {
  if [ "$(uname -m)" != 'x86_64' ]
  then
    echo 'Only x64 binaries are supported.'
    exit 1
  fi

  local min_version

  DVM_TARGET_OS=$(uname -s)
  min_version="v0.36.0"

  if compare_version "$1" "$min_version"
  then
    DVM_TARGET_TYPE="gz"
    DVM_FILE_TYPE="gzip compressed data"
  else
    DVM_TARGET_TYPE="zip"
    DVM_FILE_TYPE="Zip archive data"
  fi

  case "$DVM_TARGET_OS:$DVM_TARGET_TYPE" in
    "Darwin:gz")
      DVM_TARGET_NAME='deno_osx_x64.gz'
      ;;
    "Linux:gz")
      DVM_TARGET_NAME='deno_linux_x64.gz'
      ;;
    "Darwin:zip")
      DVM_TARGET_NAME='deno-x86_64-apple-darwin.zip'
      ;;
    "Linux:zip")
      DVM_TARGET_NAME='deno-x86_64-unknown-linux-gnu.zip'
      ;;
    *)
      echo "Unsupported operating system $DVM_TARGET_OS"
      ;;
  esac
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
  elif [ -x "$(command -v curl)" ]
  then
    curl -LJ "https://github.com/denoland/deno/releases/download/$1/$DVM_TARGET_NAME" \
        -o "$DVM_DIR/download/$1/deno-downloading.$DVM_TARGET_TYPE"
  else
    echo "wget or curl is required."
    exit 1
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
    if [ -x "$(command -v unzip)" ]
    then
      unzip "$DVM_DIR/download/$1/deno.zip" -d "$target_dir" > /dev/null
    elif [ "$DVM_TARGET_OS" = "Linux" ] && [ -x "$(command -v gunzip)" ]
    then
      gunzip -c "$DVM_DIR/download/$1/deno.zip" > "$target_dir/deno"
      chmod +x "$target_dir/deno"
    else
      echo "unzip is required."
      exit 1
    fi
    ;;
  "gz")
    if [ -x "$(command -v gunzip)" ]
    then
      gunzip -c "$DVM_DIR/download/$1/deno.gz" > "$target_dir/deno"
      chmod +x "$target_dir/deno"
    else
      echo "gunzip is required."
      exit 1
    fi
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
  local current_bin_path
  current_bin_path=$(file -h "$DVM_BIN/deno" | grep link | cut -d " " -f 5)

  if [ "$current_bin_path" = "$DVM_DIR/versions/$1/deno" ]
  then
    rm "$DVM_BIN/deno"
  fi

  if [ -f "$DVM_DIR/versions/$1/deno" ]
  then
    rm -rf "$DVM_DIR/versions/$1"

    echo "uninstalled deno $version."
  else
    echo "deno $version is not installed."
  fi
}

list_aliases() {
  local aliased_version

  if [ ! -d "$DVM_DIR/aliases" ]
  then
    return
  fi

  # shellcheck disable=SC2012
  ls "$DVM_DIR/aliases" | while read -r name
  do
    aliased_version=$(cat "$DVM_DIR/aliases/$name")

    if [ -z "$aliased_version" ] || [ ! -f "$DVM_DIR/versions/$aliased_version/deno" ]
    then
      echo "$name -> N/A"
    else
      echo "$name -> $aliased_version"
    fi
  done
}

list_local_versions() {
  get_current_version

  if [ -d "$DVM_DIR/versions" ]
  then
    # shellcheck disable=SC2012
    ls "$DVM_DIR/versions" | while read -r dir
    do
      if [ ! -f "$DVM_DIR/versions/$dir/deno" ]
      then
        continue
      fi

      if [ "$dir" = "$DVM_CURRENT_VERSION" ]
      then
        echo "-> $dir"
      else
        echo "   $dir"
      fi
    done
  fi

  list_aliases
}

list_remote_versions() {
  local releases_url
  local all_versions
  local page
  local size
  local num
  local tmp_versions
  local response

  page=1
  size=100
  num="$size"
  releases_url="https://api.github.com/repos/denoland/deno/releases?per_page=$size"

  while [ "$num" -eq "$size" ]
  do
    if [ -x "$(command -v wget)" ]
    then
      response=$(wget -O- "$releases_url&page=$page" -nv)
    elif [ -x "$(command -v curl)" ]
    then
      response=$(curl -s "$releases_url&page=$page")
    else
      echo "wget or curl is required."
      exit 1
    fi

    # shellcheck disable=SC2181
    if [ "$?" != "0" ]
    then
      echo "failed to list remote versions"
      exit 1
    fi

    tmp_versions=$(echo "$response" | grep tag_name | cut -d '"' -f 4)
    num=$(echo "$tmp_versions" | wc -l)
    page=$((page + 1))

    if [ -n "$all_versions" ]
    then
      all_versions="$all_versions\n$tmp_versions"
    else
      all_versions="$tmp_versions"
    fi
  done

  echo -e "$all_versions" | sed 'x;1!H;$!d;x'
}

check_dvm_dir() {
  if [ -z "$DVM_DIR" ]
  then
    # set default dvm directory
    DVM_DIR="$HOME/.dvm"
  fi

  if [ -z "$DVM_BIN" ]
  then
    DVM_BIN="$DVM_DIR/bin"
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

get_version() {
  if [ -f "$DVM_DIR/aliases/$1" ]
  then
    version=$(cat "$DVM_DIR/aliases/$1")

    if [ ! -f "$DVM_DIR/versions/$version/deno" ]
    then
      version="$1"
    fi
  else
    version="$1"
  fi
}

use_version() {
  if [ ! -d "$DVM_BIN" ]
  then
    mkdir -p "$DVM_BIN"
  fi

  get_version "$1"

  if [ -f "$DVM_DIR/versions/$version/deno" ]
  then
    if [ -f "$DVM_BIN/deno" ]
    then
      rm "$DVM_BIN/deno"
    fi

    ln -s "$DVM_DIR/versions/$version/deno" "$DVM_BIN/deno"

    echo "using deno $version now."
  else
    echo "deno $version is not installed."
    exit 1
  fi
}

get_current_version() {
  local current_version
  if [ -f "$DVM_BIN/deno" ]
  then
    if current_version=$("$DVM_BIN/deno" --version | grep deno | cut -d " " -f 2)
    then
      DVM_CURRENT_VERSION="v$current_version"
    fi
  fi
}

check_alias_dir() {
  if [ ! -d "$DVM_DIR/aliases" ]
  then
    mkdir -p "$DVM_DIR/aliases"
  fi
}

set_alias() {
  check_alias_dir

  if [ ! -f "$DVM_DIR/versions/$2/deno" ]
  then
    echo "deno $2 is not installed."
    exit 1
  fi

  echo "$2" >> "$DVM_DIR/aliases/$1"

  echo "$1 -> $2"
}

rm_alias() {
  local aliased_version

  check_alias_dir

  if [ ! -f "$DVM_DIR/aliases/$1" ]
  then
    echo "Alias $1 does not exist."
    exit 1
  fi

  aliased_version=$(cat "$DVM_DIR/aliases/$1")

  rm "$DVM_DIR/aliases/$1"

  echo "Deleted alias $1."
  echo "Restore it with 'dvm alias $1 $aliased_version'"
}

run_with_version() {
  get_version "$1"

  if [ ! -f "$DVM_DIR/versions/$version/deno" ]
  then
    echo "deno $version is not installed."
    exit 1
  fi

  shift

  "$DVM_DIR/versions/$version/deno" "$@"
}

locate_version() {
  local which_version
  if [ "$1" = "current" ]
  then
    get_current_version
    which_version="$DVM_CURRENT_VERSION"
  else
    which_version="$1"
  fi

  if [ -f "$DVM_DIR/versions/$which_version/deno" ]
  then
    echo "$DVM_DIR/versions/$which_version/deno"
  else
    echo "deno $which_version is not installed."
  fi
}

print_help() {
  printf "
Deno Version Manager

Usage:
  dvm install <version>             Download and install the specified version from source.
  dvm uninstall <version>           Uninstall a version.
  dvm use                           Use the specified version read from .dvmrc.
  dvm use <name>                    Use the specified version of the alias name that passed by argument.
  dvm use <version>                 Use the specified version that passed by argument.
  dvm run <name | version> [args]   Run deno on the specified version with arguments.
  dvm alias <name> <version>        Set an alias name to specified version.
  dvm unalias <name>                Delete the specified alias name.
  dvm current                       Display the current version of Deno.
  dvm ls                            List all installed versions.
  dvm ls-remote                     List all remote versions.
  dvm which [current | version]     Display the path of installed version.
  dvm clean                         Remove all downloaded packages.

Examples:
  dvm install v1.0.0
  dvm uninstall v0.42.0
  dvm use v1.0.0
  dvm alias default v1.0.0
  dvm run v1.0.0 app.ts

"
}

dvm() {
  check_dvm_dir

  if [ "$#" = "0" ]
  then
    print_help
    exit 0
  fi

  case $1 in
  install)
    # install the specified version
    shift

    if [ "$#" != "1" ]
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

    if [ "$#" != "1" ]
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

    if [ -n "$DVM_CURRENT_VERSION" ]
    then
      echo "$DVM_CURRENT_VERSION"
    else
      echo "none"
    fi

    ;;
  use)
    # change current version to specified version
    shift

    local version

    if [ -n "$1" ]
    then
      version="$1"
    elif [ -f ".dvmrc" ]
    then
      version=$(cat .dvmrc)
    else
      echo "Must specify target version or alias name."
      print_help
      exit 1
    fi

    use_version "$version"
    ;;
  clean)
    # remove all download packages.
    clean_download_cache

    ;;
  help|--help|-h)
    # print help
    print_help

    ;;
  alias)
    shift

    if [ "$#" != "2" ]
    then
      echo "Must specify alias name and target version."
      print_help
      exit 1
    fi

    set_alias "$@"

    ;;
  unalias)
    shift

    if [ "$#" != "1" ]
    then
      echo "Must specify alias name."
      print_help
      exit 1
    fi

    rm_alias "$1"
    ;;
  run)
    shift

    if [ "$#" = "0" ]
    then
      echo "Must specify target version"
      print_help
      exit 1
    fi

    run_with_version "$@"

    ;;
  which)
    shift

    local version

    if [ -n "$1" ]
    then
      version="$1"
    elif [ -f ".dvmrc" ]
    then
      version=$(cat .dvmrc)

      if [ -z "$version" ]
      then
        echo "Must specify target version in .dvmrc file."
        exit 1
      fi
    else
      echo "Must specify target version / name, or exists .dvmrc file."
      print_help
      exit 1
    fi

    locate_version "$version"

    ;;
  --version)
    # print dvm version

    echo "$DVM_VERSION"

    ;;
  *)
    echo "Unknown command $1"
    print_help

    exit 1
    ;;
  esac
}

dvm "$@"
