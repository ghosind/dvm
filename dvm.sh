#!/usr/bin/env bash
# source this script

export DVM_VERSION="v0.4.1"

dvm_success() {
  # execute true to set as success
  true
}

dvm_failure() {
  # execute false to set as fail
  false
}

dvm_compare_version() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
}

dvm_get_package_data() {
  local target_version

  DVM_TARGET_OS=$(uname -s)
  DVM_TARGET_ARCH=$(uname -m)
  target_version="$1"

  if [ "$DVM_TARGET_OS" = "Darwin" ] &&
    [ "$DVM_TARGET_ARCH" = 'arm64' ] &&
    dvm_compare_version "$target_version" "v1.6.0"
  then
    echo '[ERR] aarch64-darwin support deno v1.6.0 and above versions only.'
    dvm_failure
  fi

  if dvm_compare_version "$target_version" "v0.36.0"
  then
    DVM_TARGET_TYPE="gz"
    DVM_FILE_TYPE="gzip compressed data"
  else
    DVM_TARGET_TYPE="zip"
    DVM_FILE_TYPE="Zip archive data"
  fi

  case "$DVM_TARGET_OS:$DVM_TARGET_ARCH:$DVM_TARGET_TYPE" in
    "Darwin:x86_64:gz")
      DVM_TARGET_NAME='deno_osx_x64.gz'
      ;;
    "Linux:x86_64:gz")
      DVM_TARGET_NAME='deno_linux_x64.gz'
      ;;
    "Darwin:x86_64:zip")
      DVM_TARGET_NAME='deno-x86_64-apple-darwin.zip'
      ;;
    "Darwin:arm64:zip")
      DVM_TARGET_NAME='deno-aarch64-apple-darwin.zip'
      ;;
    "Linux:x86_64:zip")
      DVM_TARGET_NAME='deno-x86_64-unknown-linux-gnu.zip'
      ;;
    *)
      echo "[ERR] unsupported operating system $DVM_TARGET_OS ($DVM_TARGET_ARCH)."
      dvm_failure
      ;;
  esac
}

# dvm_get_latest_version
# Calls GitHub api to getting deno latest release tag name.
dvm_get_latest_version() {
  # the url of github api
  local latest_url
  # the response of requesting deno latest version
  local response
  # the latest release tag name
  local tag_name

  echo -e "\ntry to getting deno latest version ..."

  latest_url="https://api.github.com/repos/denoland/deno/releases/latest"

  if [ ! -x "$(command -v curl)" ]
  then
    echo "[ERR] curl is required."
    dvm_failure
  fi

  if ! response=$(curl -s "$latest_url")
  then
    echo "[ERR] failed to getting deno latest version."
    dvm_failure
  fi

  tag_name=$(echo "$response" | grep tag_name | cut -d '"' -f 4)

  if [ -z "$tag_name" ]
  then
    echo "[ERR] failed to getting deno latest version."
    dvm_failure
  fi

  DVM_TARGET_VERSION="$tag_name"
}

dvm_download_file() {
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
    echo "[ERR] wget or curl is required."
    dvm_failure
  fi

  if eval "$cmd"
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

  echo "[ERR] failed to download deno $version."
  dvm_failure
}

dvm_extract_file() {
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
      echo "[ERR] unzip is required."
      dvm_failure
    fi
    ;;
  "gz")
    if [ -x "$(command -v gunzip)" ]
    then
      gunzip -c "$DVM_DIR/download/$1/deno.gz" > "$target_dir/deno"
      chmod +x "$target_dir/deno"
    else
      echo "[ERR] gunzip is required."
      dvm_failure
    fi
    ;;
  *)
    ;;
  esac
}

# dvm_validate_remote_version
# Get remote version data by GitHub api (Get a release by tag name)
dvm_validate_remote_version() {
  local version
  # GitHub get release by tag name api url
  local tag_url

  version="$1"

  tag_url="https://api.github.com/repos/denoland/deno/releases/tags/$version"

  if [ ! -x "$(command -v curl)" ]
  then
    echo "[ERR] curl is required."
    dvm_failure
  fi

  if ! response=$(curl -s "$tag_url")
  then
    echo "[ERR] failed to getting deno $version data."
    dvm_failure
  fi

  tag_name=$(echo "$response" | grep tag_name | cut -d '"' -f 4)

  if [ -z "$tag_name" ]
  then
    echo "[ERR] deno '$version' not found, use 'ls-remote' command to get available versions."
    dvm_failure
  fi
}

dvm_install_version() {
  local version

  version="$1"

  if [ -z "$version" ]
  then
    dvm_get_latest_version
    version="$DVM_TARGET_VERSION"
  fi

  if [ -f "$DVM_DIR/versions/$version/deno" ]
  then
    echo "Deno $version has been installed."
    dvm_success
  fi

  dvm_validate_remote_version "$version"

  dvm_get_package_data "$version"

  if [ ! -f "$DVM_DIR/download/$version/deno.$DVM_TARGET_TYPE" ]
  then
    echo "Downloading and installing deno $version..."
    dvm_download_file "$version"
  else
    echo "Installing deno $version from cache..."
  fi

  dvm_extract_file "$version"

  echo "Deno $version has installed."
}

dvm_uninstall_version() {
  local current_bin_path

  current_bin_path=$(file -h "$DVM_BIN/deno" | grep link | cut -d " " -f 5)

  if [ "$current_bin_path" = "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
  then
    rm "$DVM_BIN/deno"
  fi

  if [ -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
  then
    rm -rf "$DVM_DIR/versions/$DVM_TARGET_VERSION"

    echo "Uninstalled deno $DVM_TARGET_VERSION."
  else
    echo "Deno $DVM_TARGET_VERSION is not installed."
  fi
}

dvm_list_aliases() {
  local aliased_version

  if [ ! -d "$DVM_DIR/aliases" ]
  then
    return
  fi

  for alias_path in "$DVM_DIR/aliases"/*
  do
    if [ ! -f "$alias_path" ]
    then
      continue;
    fi

    alias_name=${alias_path##*/}
    aliased_version=$(cat "$alias_path")

    if [ -z "$aliased_version" ] ||
      [ ! -f "$DVM_DIR/versions/$aliased_version/deno" ]
    then
      echo "$alias_name -> N/A"
    else
      echo "$alias_name -> $aliased_version"
    fi
  done
}

dvm_list_local_versions() {
  local version

  dvm_get_current_version

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

  dvm_list_aliases
}

dvm_list_remote_versions() {
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
    if [ ! -x "$(command -v curl)" ]
    then
      echo "[ERR] curl is required."
      dvm_failure
    fi

    if ! response=$(curl -s "$releases_url&page=$page")
    then
      echo "[ERR] failed to list remote versions."
      dvm_failure
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

dvm_check_dvm_dir() {
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

dvm_clean_download_cache() {
  for cache_path in "$DVM_DIR/download"/*
  do
    if [ ! -d "$cache_path" ]
    then
      continue
    fi

    [ -f "$cache_path/deno-downloading.zip" ] && rm "$cache_path/deno-downloading.zip"

    [ -f "$cache_path/deno-downloading.gz" ] && rm "$cache_path/deno-downloading.gz"

    [ -f "$cache_path/deno.zip" ] && rm "$cache_path/deno.zip"

    [ -f "$cache_path/deno.gz" ] && rm "$cache_path/deno.gz"

    rmdir "$cache_path"
  done
}

dvm_get_version_by_param() {
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

dvm_get_version() {
  local version

  dvm_get_version_by_param "$@"

  if [ -n "$DVM_TARGET_VERSION" ]
  then
    return
  fi

  if [ ! -f "./.dvmrc" ]
  then
    echo "No .dvmrc file found."
    return
  fi

  DVM_TARGET_VERSION=$(cat ./.dvmrc)
}

# dvm_use_version
# Create a symbolic link file to make the specified deno version as active
# version, the symbolic link is linking to the specified deno executable file.
dvm_use_version() {
  # deno executable file version
  local deno_version
  # target deno executable file path
  local target_path

  if [ ! -d "$DVM_BIN" ]
  then
    # create path if it is not exist
    mkdir -p "$DVM_BIN"
  fi

  dvm_get_version "$1"

  if [ -z "$DVM_TARGET_VERSION" ]
  then
    dvm_print_help
    dvm_failure
  fi

  target_dir="$DVM_DIR/versions/$DVM_TARGET_VERSION"
  target_path="$target_dir/deno"

  if [ -f "$target_path" ]
  then
    # get target deno executable file version
    deno_version=$("$target_path" --version | grep deno | cut -d " " -f 2)

    if [ "$DVM_TARGET_VERSION" != "v$deno_version" ]
    then
      # print warnning message when deno version is different with parameter.
      echo "[WARN] You may had upgraded this version, it is v$deno_version now."
    fi

    # export PATH with the target dir in front
    PATH_NO_DVMS=$(echo "$PATH" | tr ":" "\n" | grep -v "$DVM_DIR" | tr "\n" ":")
    export PATH="$target_dir":${PATH_NO_DVMS}

    echo "Using deno $DVM_TARGET_VERSION now."
  else
    echo "Deno $DVM_TARGET_VERSION is not installed, you can run 'dvm install $DVM_TARGET_VERSION' to install it."
    dvm_failure
  fi
}

dvm_get_current_version() {
  local deno_path
  local deno_dir

  if ! deno_path=$(which deno)
  then
    return
  fi

  if [[ "$deno_path" != "$DVM_DIR/versions/"* ]]
  then
    return
  fi

  deno_dir=${deno_path%/deno}

  DVM_DENO_VERSION=${deno_dir##*/}
}

dvm_check_alias_dir() {
  if [ ! -d "$DVM_DIR/aliases" ]
  then
    mkdir -p "$DVM_DIR/aliases"
  fi
}

dvm_set_alias() {
  local alias_name
  local version

  dvm_check_alias_dir

  alias_name="$1"
  version="$2"

  if [ ! -f "$DVM_DIR/versions/$version/deno" ]
  then
    echo "[ERR] deno $version is not installed."
    dvm_failure
  fi

  echo "$version" > "$DVM_DIR/aliases/$alias_name"

  echo "$alias_name -> $version"
}

dvm_rm_alias() {
  local alias_name
  local aliased_version

  dvm_check_alias_dir

  alias_name="$1"

  if [ ! -f "$DVM_DIR/aliases/$alias_name" ]
  then
    echo "[ERR] alias $alias_name does not exist."
    dvm_failure
  fi

  aliased_version=$(cat "$DVM_DIR/aliases/$alias_name")

  rm "$DVM_DIR/aliases/$alias_name"

  echo "Deleted alias $alias_name."
  echo "Restore it with 'dvm alias $alias_name $aliased_version'."
}

dvm_run_with_version() {
  if [ ! -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
  then
    echo "[ERR] deno $DVM_TARGET_VERSION is not installed."
    dvm_failure
  fi

  echo "Running with deno $DVM_TARGET_VERSION."

  "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" "$@"
}

dvm_locate_version() {
  local target_version

  target_version="$DVM_TARGET_VERSION"

  if [ "$1" = "current" ]
  then
    dvm_get_current_version
    if [ -n "$DVM_DENO_VERSION" ]
    then
      target_version="$DVM_DENO_VERSION"
    fi
  fi

  if [ -f "$DVM_DIR/versions/$target_version/deno" ]
  then
    echo "$DVM_DIR/versions/$target_version/deno"
  else
    echo "Deno $target_version is not installed."
  fi
}

dvm_get_dvm_latest_version() {
  local request_url
  local field
  local response

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

  if [ ! -x "$(command -v curl)" ]
  then
    echo "[ERR] curl is required."
    dvm_failure
  fi

  if ! response=$(curl -s "$request_url")
  then
    echo "[ERR] failed to get the latest DVM version."
    dvm_failure
  fi

  DVM_LATEST_VERSION=$(echo "$response" | grep tag_name | cut -d '"' -f $field)
}

dvm_update_dvm() {
  if ! cd "$DVM_DIR" 2>/dev/null
  then
    echo "[ERR] failed to update dvm."
    dvm_failure
  fi

  # reset changes if exists
  git reset --hard HEAD
  git fetch
  git checkout "$DVM_LATEST_VERSION"
}

dvm_fix_invalid_versions() {
  local version

  if [ ! -d "$DVM_DIR/doctor_temp" ]
  then
    return
  fi

  for version_path in "$DVM_DIR/doctor_temp/"*
  do
    version=${version_path##*/}

    if [ -d "$DVM_DIR/versions/$version" ]
    then
      rm -rf "$version_path"
    else
      mv "$version_path" "$DVM_DIR/versions/$version"
    fi
  done

  rmdir "$DVM_DIR/doctor_temp"
}

dvm_print_doctor_message() {
  local invalid_message
  local corrupted_message

  invalid_message="$1"
  corrupted_message="$2"

  if [ -z "$invalid_message" ] && [ -z "$corrupted_message" ]
  then
    echo "Everything is ok."
    return
  fi

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
}

dvm_scan_and_fix_versions() {
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

        if [ "$mode" = "fix" ]
        then
          mkdir -p "$DVM_DIR/doctor_temp"
          mv -f "$version_path" "$DVM_DIR/doctor_temp/v$deno_version"
        fi
      fi
    fi
  done

  if [ "$mode" = "fix" ]
  then
    dvm_fix_invalid_versions
  else
    dvm_print_doctor_message "$invalid_message" "$corrupted_message"
  fi
}

dvm_get_rc_file() {
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

dvm_confirm_with_prompt() {
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
    dvm_success
    ;;
  *)
    dvm_failure
    ;;
  esac
}

dvm_purge_dvm() {
  local content

  rm -rf "$DVM_DIR"

  dvm_get_rc_file

  content=$(sed "/Deno Version Manager/d;/DVM_DIR/d;/DVM_BIN/d" "$DVM_RC_FILE")
  echo "$content" > "$DVM_RC_FILE"

  echo "DVM has been removed from your computer."
}

dvm_print_help() {
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
  dvm_check_dvm_dir

  if [ "$#" = "0" ]
  then
    dvm_print_help
    dvm_success
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

    dvm_install_version "$version"

    ;;
  uninstall)
    # uninstall the specified version
    shift

    dvm_get_version "$@"
    if [ "$DVM_TARGET_VERSION" = "" ]
    then
      dvm_print_help
      dvm_failure
    fi

    dvm_uninstall_version "$DVM_TARGET_VERSION"

    ;;
  list | ls)
    # list all local versions
    dvm_list_local_versions

    ;;
  list-remote | ls-remote)
    # list all remote versions
    dvm_list_remote_versions

    ;;
  current)
    # get the current version
    dvm_get_current_version

    if [ -n "$DVM_DENO_VERSION" ]
    then
      echo "$DVM_DENO_VERSION"
    elif [ -x "$(command -v deno)" ]
    then
      version=$(deno --version | grep "deno" | cut -d " " -f 2)
      echo "system (v$version)"
    else
      echo "none"
    fi

    ;;
  use)
    # change current version to specified version
    shift

    dvm_use_version "$@"

    ;;
  clean)
    # remove all download packages.
    dvm_clean_download_cache

    ;;
  alias)
    shift

    if [ "$#" -lt "2" ]
    then
      dvm_print_help
      dvm_failure
    fi

    dvm_set_alias "$@"

    ;;
  unalias)
    shift

    if [ "$#" -lt "1" ]
    then
      dvm_print_help
      dvm_failure
    fi

    dvm_rm_alias "$1"
    ;;
  run)
    shift

    dvm_get_version "$@"

    if [ "$DVM_TARGET_VERSION" = "" ]
    then
      dvm_print_help
      dvm_failure
    fi

    if [ "$#" != "0" ]
    then
      shift
    fi

    dvm_run_with_version "$@"

    ;;
  which)
    shift

    dvm_get_version "$@"

    if [ -z "$DVM_TARGET_VERSION" ]
    then
      dvm_print_help
      dvm_failure
    fi

    dvm_locate_version "$@"

    ;;
  upgrade)
    dvm_get_dvm_latest_version

    if [ "$DVM_LATEST_VERSION" = "$DVM_VERSION" ]
    then
      echo "dvm is update to date."
      dvm_success
    fi

    dvm_update_dvm

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
        echo "[ERR] unsupprot option \"$1\"."
        dvm_failure
        ;;
      esac

      shift
    done

    if [ "$mode" == "fix" ]
    then
      dvm_confirm_with_prompt "Doctor fix command will remove all duplicated / corrupted versions, do you want to continue?"
    fi

    dvm_scan_and_fix_versions "$mode"

    ;;
  purge)
    dvm_confirm_with_prompt "Do you want to remove DVM from your computer?"

    dvm_confirm_with_prompt "Remove dvm will also remove installed deno(s), do you want to continue?"

    dvm_purge_dvm

    ;;
  help|--help|-h)
    # print help
    dvm_print_help

    ;;
  --version)
    # print dvm version

    echo "$DVM_VERSION"

    ;;
  *)
    echo "[ERR] unknown command $1."
    dvm_print_help

    dvm_failure
    ;;
  esac
}
