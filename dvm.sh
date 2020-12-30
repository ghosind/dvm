#!/usr/bin/env bash

DVM_VERSION="v0.3.4"

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
  local target_version

  target_version="$1"

  DVM_TARGET_OS=$(uname -s)
  min_version="v0.36.0"

  if compare_version "$target_version" "$min_version"
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
      exit 1
      ;;
  esac
}

# get_latest_version
# Calls GitHub api to getting deno latest release tag name.
get_latest_version() {
  # the command of request deno latest version
  local cmd
  # the url of github api
  local latest_url
  # the response of requesting deno latest version
  local response
  # the latest release tag name
  local tag_name

  echo -e "\ntry to getting deno latest version ..."

  latest_url="https://api.github.com/repos/denoland/deno/releases/latest"

  if [ -x "$(command -v wget)" ]
  then
    cmd="wget -O- $latest_url -nv"
  elif [ -x "$(command -v curl)" ]
  then
    cmd="curl -s $latest_url"
  else
    echo "wget or curl is required."
    exit 1
  fi

  if ! response=$($cmd)
  then
    echo "failed to getting deno latest version"
    exit 1
  fi

  tag_name=$(echo "$response" | grep tag_name | cut -d '"' -f 4)

  if [ -z "$tag_name" ]
  then
    echo "failed to getting deno latest version"
    exit 1
  fi

  DVM_TARGET_VERSION="$tag_name"
}

download_file() {
  local cmd
  local version
  local url
  local temp_file

  version="$1"

  if [ ! -d "$DVM_DIR/download/$version" ]
  then
    mkdir -p "$DVM_DIR/download/$version"
  fi

  if [ -z "$DVM_INSTALL_REGISTRY" ]
  then
    DVM_INSTALL_REGISTRY="https://github.com/denoland/deno/releases/download"
  fi

  url="$DVM_INSTALL_REGISTRY/$version/$DVM_TARGET_NAME"
  temp_file="$DVM_DIR/download/$version/deno-downloading.$DVM_TARGET_TYPE"

  if [ -x "$(command -v wget)" ]
  then
    cmd="wget $url -O $temp_file"
  elif [ -x "$(command -v curl)" ]
  then
    cmd="curl -LJ $url -o $temp_file"
  else
    echo "wget or curl is required."
    exit 1
  fi

  if $cmd
  then
    local file_type
    file_type=$(file "$temp_file")

    if [[ $file_type == *"$DVM_FILE_TYPE"* ]]
    then
      mv "$temp_file" "$DVM_DIR/download/$version/deno.$DVM_TARGET_TYPE"
      return
    fi
  fi

  if [ -f "$temp_file" ]
  then
    rm "$temp_file"
  fi

  echo "Failed to download deno $version."
  exit 1
}

extract_file() {
  local target_dir

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

# validate_remote_version
# Get remote version data by GitHub api (Get a release by tag name)
validate_remote_version() {
  local version
  # GitHub get release by tag name api url
  local tag_url

  version="$1"

  tag_url="https://api.github.com/repos/denoland/deno/releases/tags/$version"

  if [ -x "$(command -v wget)" ]
  then
    cmd="wget -O- $tag_url -nv"
  elif [ -x "$(command -v curl)" ]
  then
    cmd="curl -s $tag_url"
  else
    echo "wget or curl is required."
    exit 1
  fi

  if ! response=$($cmd)
  then
    echo "Failed to getting deno $version data"
    exit 1
  fi

  tag_name=$(echo "$response" | grep tag_name | cut -d '"' -f 4)

  if [ -z "$tag_name" ]
  then
    echo "Deno '$version' not found, use 'ls-remote' command to get available versions."
    exit 1
  fi
}

install_version() {
  local version

  version="$1"

  if [ -z "$version" ]
  then
    get_latest_version
    version="$DVM_TARGET_VERSION"
  fi

  if [ -f "$DVM_DIR/versions/$version/deno" ]
  then
    echo "deno $version has been installed."
    exit 0
  fi

  validate_remote_version "$version"

  get_package_data "$version"

  if [ ! -f "$DVM_DIR/download/$version/deno.$DVM_TARGET_TYPE" ]
  then
    echo "Downloading and installing deno $version..."
    download_file "$version"
  else
    echo "Installing deno $version from cache..."
  fi

  extract_file "$version"

  echo "deno $version has installed."
}

uninstall_version() {
  local current_bin_path

  current_bin_path=$(file -h "$DVM_BIN/deno" | grep link | cut -d " " -f 5)

  if [ "$current_bin_path" = "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
  then
    rm "$DVM_BIN/deno"
  fi

  if [ -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
  then
    rm -rf "$DVM_DIR/versions/$DVM_TARGET_VERSION"

    echo "uninstalled deno $DVM_TARGET_VERSION."
  else
    echo "deno $DVM_TARGET_VERSION is not installed."
  fi
}

list_aliases() {
  local aliased_version

  if [ ! -d "$DVM_DIR/aliases" ]
  then
    return
  fi

  for path in "$DVM_DIR/aliases"/*
  do
    if [ ! -f "$path" ]
    then
      continue;
    fi

    alias_name=${path##*/}
    aliased_version=$(cat "$path")

    if [ -z "$aliased_version" ] ||
      [ ! -f "$DVM_DIR/versions/$aliased_version/deno" ]
    then
      echo "$alias_name -> N/A"
    else
      echo "$alias_name -> $aliased_version"
    fi
  done
}

list_local_versions() {
  local version

  get_current_version

  if [ -d "$DVM_DIR/versions" ]
  then
    for dir in "$DVM_DIR/versions"/*
    do
      if [ ! -f "$dir/deno" ]
      then
        continue
      fi

      version=${dir##*/}

      if [ "$version" = "$DVM_DENO_VERSION" ]
      then
        echo "-> $version"
      else
        echo "   $version"
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
  local cmd

  page=1
  size=100
  num="$size"
  releases_url="https://api.github.com/repos/denoland/deno/releases?per_page=$size"

  while [ "$num" -eq "$size" ]
  do
    if [ -x "$(command -v wget)" ]
    then
      cmd="wget -O- $releases_url&page=$page -nv"
    elif [ -x "$(command -v curl)" ]
    then
      cmd="curl -s $releases_url&page=$page"
    else
      echo "wget or curl is required."
      exit 1
    fi

    if ! response=$($cmd)
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
  for path in "$DVM_DIR/download"/*
  do
    if [ ! -d "$path" ]
    then
      continue
    fi

    [ -f "$path/deno-downloading.zip" ] && rm "$path/deno-downloading.zip"

    [ -f "$path/deno-downloading.gz" ] && rm "$path/deno-downloading.gz"

    [ -f "$path/deno.zip" ] && rm "$path/deno.zip"

    [ -f "$path/deno.gz" ] && rm "$path/deno.gz"

    rmdir "$path"
  done
}

get_version_by_param() {
  DVM_TARGET_VERSION=""

  if [ "$#" = "0" ]
  then
    return
  fi

  if [ -f "$DVM_DIR/aliases/$1" ]
  then
    DVM_TARGET_VERSION=$(cat "$DVM_DIR/aliases/$1")

    if [ ! -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
    then
      DVM_TARGET_VERSION="$1"
    fi
  else
    DVM_TARGET_VERSION="$1"
  fi
}

get_version() {
  local version

  get_version_by_param "$@"

  if [ -n "$DVM_TARGET_VERSION" ]
  then
    return
  fi

  if [ ! -f "./.dvmrc" ]
  then
    echo "No .dvmrc file found"
    return
  fi

  version=$(cat ./.dvmrc)
  if [ -f "$DVM_DIR/versions/$version/deno" ]
  then
    DVM_TARGET_VERSION="$version"
  fi
}

# use_version
# Create a symbolic link file to make the specified deno version as active
# version, the symbolic link is linking to the specified deno executable file.
use_version() {
  # deno executable file version
  local deno_version
  # target deno executable file path
  local target_path

  if [ ! -d "$DVM_BIN" ]
  then
    # create path if it is not exist
    mkdir -p "$DVM_BIN"
  fi

  get_version "$1"

  if [ -z "$DVM_TARGET_VERSION" ]
  then
    print_help
    exit 1
  fi

  target_path="$DVM_DIR/versions/$DVM_TARGET_VERSION/deno"

  if [ -f "$target_path" ]
  then
    # get target deno executable file version
    deno_version=$("$target_path" --version | grep deno | cut -d " " -f 2)

    if [ "$DVM_TARGET_VERSION" != "v$deno_version" ]
    then
      # print warnning message when deno version is different with parameter.
      echo "[WARN] You may had upgraded this version, it is v$deno_version now."
    fi

    # create a new symbolic link, and link to specified deno executable file.
    ln -sf "$target_path" "$DVM_BIN/deno"

    echo "using deno $DVM_TARGET_VERSION now."
  else
    echo "deno $DVM_TARGET_VERSION is not installed."
    exit 1
  fi
}

get_current_version() {
  local deno_path
  local deno_dir

  if [ ! -f "$DVM_BIN/deno" ]
  then
    return
  fi

  deno_path=$(readlink "$DVM_BIN/deno")
  deno_dir=${deno_path%/deno}

  DVM_DENO_VERSION=${deno_dir##*/}
}

check_alias_dir() {
  if [ ! -d "$DVM_DIR/aliases" ]
  then
    mkdir -p "$DVM_DIR/aliases"
  fi
}

set_alias() {
  local alias_name
  local version

  check_alias_dir

  alias_name="$1"
  version="$2"

  if [ ! -f "$DVM_DIR/versions/$version/deno" ]
  then
    echo "deno $version is not installed."
    exit 1
  fi

  echo "$version" > "$DVM_DIR/aliases/$alias_name"

  echo "$alias_name -> $version"
}

rm_alias() {
  local alias_name
  local aliased_version

  check_alias_dir

  alias_name="$1"

  if [ ! -f "$DVM_DIR/aliases/$alias_name" ]
  then
    echo "Alias $alias_name does not exist."
    exit 1
  fi

  aliased_version=$(cat "$DVM_DIR/aliases/$alias_name")

  rm "$DVM_DIR/aliases/$alias_name"

  echo "Deleted alias $alias_name."
  echo "Restore it with 'dvm alias $alias_name $aliased_version'"
}

run_with_version() {
  if [ ! -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
  then
    echo "deno $DVM_TARGET_VERSION is not installed."
    exit 1
  fi

  echo "Running with deno $DVM_TARGET_VERSION"

  "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" "$@"
}

locate_version() {
  local target_version

  target_version="$DVM_TARGET_VERSION"

  if [ "$1" = "current" ]
  then
    get_current_version
    if [ -n "$DVM_DENO_VERSION" ]
    then
      target_version="$DVM_DENO_VERSION"
    fi
  fi

  if [ -f "$DVM_DIR/versions/$target_version/deno" ]
  then
    echo "$DVM_DIR/versions/$target_version/deno"
  else
    echo "deno $target_version is not installed."
  fi
}

get_dvm_latest_version() {
  local request_url
  local field
  local request
  local response

  DVM_SOURCE="gitee"

  case "$DVM_SOURCE" in
  gitee)
    request_url="https://gitee.com/api/v5/repos/ghosind/dvm/releases/latest"
    field="6"
    ;;
  github|*)
    request_url="https://api.github.com/repos/ghosind/dvm/releases/latest"
    field="4"
    ;;
  esac

  if [ -x "$(command -v wget)" ]
  then
    request="wget -O- $request_url -nv"
  elif [ -x "$(command -v curl)" ]
  then
    request="curl -s $request_url"
  else
    echo "wget or curl is required."
    exit 1
  fi

  if ! response=$($request)
  then
    echo "failed to get the latest DVM version."
    exit 1
  fi

  DVM_LATEST_VERSION=$(echo "$response" | grep tag_name | cut -d '"' -f $field)
}

update_dvm() {
  if ! cd "$DVM_DIR" 2>/dev/null
  then
    echo "Failed to update dvm."
    exit 1
  fi

  # reset changes if exists
  git reset --hard HEAD
  git fetch
  git checkout "$DVM_LATEST_VERSION"
}

scan_and_fix_versions() {
  local mode
  local raw_output
  local invalid_message
  local corrupted_message
  local version
  local deno_version

  mode="$1"

  for version_path in "$DVM_DIR/versions/"*
  do
    if [ ! -f "$version_path/deno" ]
    then
      continue
    fi

    version=${version_path##*/}

    raw_output=$("$version_path/deno" --version 2>/dev/null)
    
    if [ -z "$raw_output" ]
    then
      corrupted_message="$corrupted_message$version\n"

      if [ "$mode" = "fix" ]
      then
        rm -rf "$version_path"
      fi
    else
      deno_version=$(echo "$raw_output" | grep deno | cut -d " " -f 2)

      if [ "$version" != "v$deno_version" ]
      then
        invalid_message="$invalid_message$version -> v$deno_version\n"
      fi
    fi
  done

  if [ "$mode" = "fix" ]
  then
    # todo: fix invalid versions
    return
  fi

  if [ -z "$invalid_message" ] && [ -z "$corrupted_message" ]
  then
    echo "Everything is ok."
  else
    if [ -n "$invalid_message" ]
    then
      echo "Invalid versions:"
      echo -e "$invalid_message"
    fi
    
    if [ -n "$corrupted_message" ]
    then
      echo "Corrupted versions:"
      echo -e "$corrupted_message"
    fi

    echo "You can run \"dvm doctor --fix\" to fix these errors."
  fi
}

get_rc_file() {
  case ${SHELL##*/} in
  bash)
    DVM_RC_FILE="$HOME/.bashrc"
    ;;
  zsh)
    DVM_RC_FILE="$HOME/.zshrc"
    ;;
  *)
    DVM_RC_FILE="$HOME/.profile"
    ;;
  esac
}

confirm_with_prompt() {
  local confirm
  local prompt

  if [ "$#" = 0 ]
  then
    return
  fi

  prompt="$1"

  echo -n "$prompt (y/n) "
  read -r confirm

  case "$confirm" in
  y|Y)
    ;;
  n|N)
    exit 0
    ;;
  *)
    exit 1
    ;;
  esac
}

purge_dvm() {
  local content

  rm -rf "$DVM_DIR"

  get_rc_file

  content=$(sed "/Deno Version Manager/d;/DVM_DIR/d;/DVM_BIN/d" "$DVM_RC_FILE")
  echo "$content" > "$DVM_RC_FILE"

  echo "DVM has been removed from your computer."
}

print_help() {
  printf "
Deno Version Manager

Usage:
  dvm install                       Download and install the latest version or the version reading from .dvmrc file.
    <version>                       Download and install the specified version from source.
    --registry=<registry>           Download and install deno with the specified registry.
  dvm uninstall [name|version]      Uninstall a specified version.
  dvm use [name|version]            Use the specified version that passed by argument or read from .dvmrc.
  dvm run <name|version> [args]     Run deno on the specified version with arguments.
  dvm alias <name> <version>        Set an alias name to specified version.
  dvm unalias [name|version]        Delete the specified alias name.
  dvm current                       Display the current version of Deno.
  dvm ls                            List all installed versions.
  dvm ls-remote                     List all remote versions.
  dvm which [current|name|version]  Display the path of installed version.
  dvm clean                         Remove all downloaded packages.
  dvm doctor                        Scan installed versions and find invalid / corrupted versions.
    --fix                           Scan and fix all invalid / corrupted versions.
  dvm upgrade                       Upgrade dvm itself.
  dvm purge                         Remove dvm from your computer.
  dvm help                          Show this message.

Examples:
  dvm install v1.0.0
  dvm uninstall v0.42.0
  dvm use v1.0.0
  dvm alias default v1.0.0
  dvm run v1.0.0 app.ts

"
}

dvm() {
  local version
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

    version=""

    while [ "$#" -gt "0" ]
    do
      case "$1" in
      "--registry="*)
        DVM_INSTALL_REGISTRY=${1#--registry=}
        ;;
      *)
        version="$1"
        ;;
      esac

      shift
    done

    if [ -z "$version" ]
    then
      if [ -f "./.dvmrc" ]
      then
        version=$(cat ./.dvmrc)
      else
        echo "No .dvmrc file found"
      fi
    fi

    install_version "$version"

    ;;
  uninstall)
    # uninstall the specified version
    shift

    get_version "$@"
    if [ "$DVM_TARGET_VERSION" = "" ]
    then
      print_help
      exit 1
    fi

    uninstall_version "$DVM_TARGET_VERSION"

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

    if [ -n "$DVM_DENO_VERSION" ]
    then
      echo "$DVM_DENO_VERSION"
    else
      echo "none"
    fi

    ;;
  use)
    # change current version to specified version
    shift

    use_version "$@"

    ;;
  clean)
    # remove all download packages.
    clean_download_cache

    ;;
  alias)
    shift

    if [ "$#" -lt "2" ]
    then
      print_help
      exit 1
    fi

    set_alias "$@"

    ;;
  unalias)
    shift

    if [ "$#" -lt "1" ]
    then
      print_help
      exit 1
    fi

    rm_alias "$1"
    ;;
  run)
    shift

    get_version "$@"

    if [ "$DVM_TARGET_VERSION" = "" ]
    then
      print_help
      exit 1
    fi

    if [ "$#" != "0" ]
    then
      shift
    fi

    run_with_version "$@"

    ;;
  which)
    shift

    get_version "$@"

    if [ -z "$DVM_TARGET_VERSION" ]
    then
      print_help
      exit 1
    fi

    locate_version "$@"

    ;;
  upgrade)
    get_dvm_latest_version

    if [ "$DVM_LATEST_VERSION" = "$DVM_VERSION" ]
    then
      echo "dvm is update to date."
      exit 0
    fi

    update_dvm

    ;;
  doctor)
    local mode

    shift

    while [ "$#" -gt "0" ]
    do
      case "$1" in
      "--fix")
        mode="fix"
        ;;
      *)
        echo "Unsupprot option \"$1\""
        exit 1
        ;;
      esac

      shift
    done

    if [ "$mode" == "fix" ]
    then
      confirm_with_prompt "Doctor fix command will remove all duplicated / corrupted versions, do you want to continue?"
    fi

    scan_and_fix_versions "$mode"

    ;;
  purge)
    confirm_with_prompt "Do you want to remove DVM from your computer?"

    confirm_with_prompt "Remove dvm will also remove installed deno(s), do you want to continue?"

    purge_dvm

    ;;
  help|--help|-h)
    # print help
    print_help

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
