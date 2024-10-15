#!/usr/bin/env bash
# Deno Version Manager
# Copyright (C) 2020 ~ 2024, Chen Su and all contributors.
# A lightweight, and powerful Deno version manager for MacOS, Linux, WSL, and
# Windows with Bash.

{ # Ensure the integrality of this script

export DVM_VERSION="v0.8.3"

######################
## Helper Functions ##
######################
{
  ################
  ## Environent ##
  ################
  {
    # Check aliases directory, and try to create it if is not existed.
    dvm_check_alias_dir() {
      if [ ! -d "$DVM_DIR/aliases" ]
      then
        mkdir -p "$DVM_DIR/aliases"
      fi
    }

    # Gets user profile file path by the shell.
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

      dvm_debug "profile file: $DVM_PROFILE_FILE"
    }

    # Check whether a command exists or not.
    # Parameters:
    # $1: command to check.
    dvm_has() {
      command -v "$1" > /dev/null
    }

    # Set the environment variables to the default values.
    dvm_set_default_env() {
      # set default dvm directory
      DVM_DIR=${DVM_DIR:-$HOME/.dvm}

      # Set modes
      DVM_COLOR_MODE=true
      DVM_QUIET_MODE=false
      DVM_VERBOSE_MODE=false

      # Set global variables to default values
      DVM_DENO_VERSION=""
      DVM_FILE_TYPE=""
      DVM_INSTALL_MODE="binary"
      DVM_INSTALL_REGISTRY=""
      DVM_INSTALL_SKIP_VALIDATION=false
      DVM_INSTALL_SKIP_CACHE=false
      DVM_LATEST_VERSION=""
      DVM_PROFILE_FILE=""
      DVM_REMOTE_VERSIONS=""
      DVM_REQUEST_RESPONSE=""
      DVM_SOURCE=""
      DVM_TARGET_NAME=""
      DVM_TARGET_TYPE=""
      DVM_TARGET_VERSION=""
    }

    # Remove Deno path from the global environment variable `PATH` that added
    # by DVM.
    dvm_strip_path() {
      echo "$PATH" | tr ":" "\n" | grep -v "$DVM_DIR" | tr "\n" ":"
    }
  }

  ######################
  ## Handle Parameter ##
  ######################
  {
    # Check all parameters and try to match available options.
    dvm_parse_options() {
      while [ "$#" -gt "0" ]
      do
        case "$1" in
          "-q"|"--quiet")
            DVM_QUIET_MODE=true
            ;;
          "--color")
            DVM_COLOR_MODE=true
            ;;
          "--no-color")
            DVM_COLOR_MODE=false
            ;;
          "--verbose")
            DVM_VERBOSE_MODE=true
            ;;
          *)
            ;;
        esac

        shift
      done
    }
  }

  ###########
  ## Input ##
  ###########
  {
    # Print a prompt message, and get the comfirm (yes or no) from the user
    # input.
    # Parameters:
    # $1: the prompt message.
    dvm_confirm_with_prompt() {
      local confirm
      local prompt

      if [ "$#" = 0 ]
      then
        return
      fi

      prompt="$1"
      echo -n "$prompt (y/n): "

      while true
      do
        read -r confirm

        case "$confirm" in
        [yY]*)
          return 0
          ;;
        [nN]*)
          return 1
          ;;
        *)
          ;;
        esac

        echo -n "Please type 'y' or 'n': "
      done
    }
  }

  ###################
  ## Network Tools ##
  ###################
  {
    # Download file from the specific url, and save the file to the specific
    # path.
    # Parameters:
    # - $1: downloading url.
    # - $2: the path of downloaded file.
    dvm_download_file() {
      local url
      local file
      local cmd

      url="$1"
      file="$2"

      dvm_debug "downloading url: $url"
      dvm_debug "download destination file: $file"

      if dvm_has curl
      then
        cmd="curl -LJ $url -o $file"
        if [ "$DVM_QUIET_MODE" = true ]
        then
          cmd="$cmd -s"
        elif [ "$DVM_VERBOSE_MODE" = true ]
        then
          cmd="$cmd -v"
        fi
      else
        dvm_print_error "curl is required."
        dvm_failure
        return
      fi

      dvm_debug "download file command: $cmd"

      if ! eval "$cmd"
      then
        dvm_failure
      fi
    }

    # Send a GET request to the specific url, and save response to the
    # `DVM_REQUEST_RESPONSE` variable.
    # Parameters:
    # - $1: request url.
    # - $2...: options for curl.
    dvm_request() {
      local url

      # Clear response content.
      DVM_REQUEST_RESPONSE=""

      if ! dvm_has curl
      then
        dvm_print_error "curl is required"
        dvm_failure
        return
      fi

      url="$1"
      shift

      cmd="curl -s '$url' $*"

      if [ "$DVM_VERBOSE_MODE" = true ]
      then
        cmd="$cmd -v"
      fi

      if [ -n "$GITHUB_API_TOKEN" ] && [[ "$url" = "https://api.github.com/"* ]]
      then
        cmd="$cmd -H \"Authorization: Bearer $GITHUB_API_TOKEN\""
      fi

      dvm_debug "request url: $url"
      dvm_debug "request command: $cmd"

      if ! DVM_REQUEST_RESPONSE=$(eval "$cmd")
      then
        dvm_failure
        return
      fi

      dvm_debug "request response: $DVM_REQUEST_RESPONSE"
    }
  }

  ############
  ## Output ##
  ############
  {
    # Print debug message in the verbose mode.
    # Parameters:
    # - $1...: the message to print.
    dvm_debug() {
      if [ "$DVM_VERBOSE_MODE" = true ]
      then
        echo -e "[DEBUG]" "$@"
      fi
    }

    # Print messages without quiet mode.
    # Parameters:
    # - $1...: the message to print.
    dvm_print() {
      if [ "$DVM_QUIET_MODE" = true ]
      then
        return
      fi

      echo -e "$@"
    }

    # Print error message with red color text.
    # Parameters:
    # $1...: the message to print.
    dvm_print_error() {
      dvm_print_with_color "31" "[ERR]" "$@"
    }

    # Print warning message with yellow color text.
    # Parameters:
    # $1...: the message to print.
    dvm_print_warning() {
      dvm_print_with_color "33" "[WARN]" "$@"
    }

    # Print message with the specific color.
    # Parameters:
    # - $1: the color code.
    # - $2...: the message to print.
    dvm_print_with_color() {
      local color="$1"

      shift

      if [ "$DVM_COLOR_MODE" = true ] && [ -n "$color" ]
      then
        dvm_print "\x1b[${color}m$*\x1b[0m"
      else
        dvm_print "$@"
      fi
    }
  }

  ###################
  ## Return Status ##
  ###################
  {
    # Set return status to true.
    dvm_success() {
      # execute true to set as success
      true
    }

    # Set return status to false.
    dvm_failure() {
      # execute false to set as fail
      false
    }
  }

  ####################
  ## Version Handle ##
  ####################
  {
    # Compare two version number.
    # Parameters:
    # $1, $2: the version number to compare.
    dvm_compare_version() {
      test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$2"
    }

    # Try to getting the active Deno version, and set it to `DVM_DENO_VERSION`
    # variable.
    dvm_get_current_version() {
      local deno_path
      local deno_dir

      if ! deno_path=$(which deno 2>/dev/null)
      then
        return
      fi

      if [[ "$deno_path" != "$DVM_DIR/versions/"* ]]
      then
        return
      fi

      deno_dir=${deno_path%/deno}

      DVM_DENO_VERSION=${deno_dir##*/}

      dvm_debug "active deno version: $DVM_DENO_VERSION"
    }

    # Try to get a Deno version from the parameters or the .dvmrc file (the
    # current directory or the user home directory).
    # Parameters:
    # $1...: the Deno version.
    dvm_get_version() {
      local version

      dvm_get_version_by_param "$@"

      if [ -n "$DVM_TARGET_VERSION" ]
      then
        return
      fi

      dvm_get_version_from_dvmrc
    }

    # Try to get a valid and installed Deno version from the parameters.
    # Parameters:
    # $1...: the Deno version.
    dvm_get_version_by_param() {
      DVM_TARGET_VERSION=""

      while [[ "$1" == "-"* ]]
      do
        shift
      done

      if [ "$#" = "0" ]
      then
        return
      fi

      if [ -f "$DVM_DIR/aliases/$1" ]
      then
        DVM_TARGET_VERSION=$(head -n 1 "$DVM_DIR/aliases/$1")

        if [ ! -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
        then
          DVM_TARGET_VERSION="$1"
        fi
      else
        DVM_TARGET_VERSION="$1"
      fi
    }

    # Try to read version from .dvmrc file in the current working directory or
    # the user home directory.
    dvm_get_version_from_dvmrc() {
      if dvm_read_dvmrc_file "$PWD"
      then
        return 0
      fi

      if [ "$PWD" != "$HOME" ] && dvm_read_dvmrc_file "$HOME"
      then
        return 0
      fi

      return 1
    }

    # Read .dvmrc file from the specified path, and set it to
    # `DVM_TARGET_VERSION` variable if the file is not empty.
    # Parameters:
    # - $1: path directory
    dvm_read_dvmrc_file() {
      local version
      local file_dir="$1"
      local file="$file_dir/.dvmrc"

      if [ -f "$file" ]
      then
        dvm_debug "reading version from file $file"
        version=$(head -n 1 "$file")
      else
        dvm_debug "no .dvmrc found in $file_dir"
        return 1
      fi

      if [ -n "$version" ]
      then
        dvm_print "Found '$file' with version $version"
        DVM_TARGET_VERSION="$version"
        return 0
      else
        dvm_debug "empty .dvmrc file $file_dir"
      fi

      return 1
    }
  }
}

###################
## Command alias ##
###################
{
  # Set an alias to the specific Deno version, and it will overwrite if the
  # alias was created.
  # Parameters:
  # $1: the alias name to be set.
  # $2: the Deno version to alias.
  dvm_set_alias() {
    local alias_name
    local version

    dvm_check_alias_dir

    while [ "$#" -gt "0" ]
    do
      case "$1" in
      "-"*)
        ;;
      *)
        if [ -z "$alias_name" ]
        then
          alias_name="$1"
        elif [ -z "$version" ]
        then
          version="$1"
        fi
      esac

      shift
    done

    if [ -z "$alias_name" ] || [ -z "$version" ]
    then
      dvm_print_help
      dvm_failure
      return
    fi

    if [ ! -f "$DVM_DIR/versions/$version/deno" ]
    then
      dvm_print_error "deno $version is not installed."
      dvm_failure
      return
    fi

    echo "$version" > "$DVM_DIR/aliases/$alias_name"

    dvm_print "$alias_name -> $version"
  }
}

###################
## Command clean ##
###################
{
  # Clean downloading caches in the disk.
  dvm_clean_download_cache() {
    if [ ! -d "$DVM_DIR/download" ]
    then
      return
    fi

    if [ -z "$(ls -A "$DVM_DIR/download")" ]
    then
      return
    fi

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

  if [ -d "$DVM_DIR/cache" ]
  then
    rm -rf "$DVM_DIR/cache"
  fi
}

#####################
## Command current ##
#####################
{
  # Gets the current Deno version and prints. It will print `system (vX.X.X)`
  # if Deno doesn't install by DVM.
  dvm_print_current_version() {
    local deno_version

    if ! dvm_has deno
    then
      dvm_print "none"
      return
    fi

    dvm_get_current_version

    if [ -n "$DVM_DENO_VERSION" ]
    then
      dvm_print "$DVM_DENO_VERSION"
    else
      deno_version=$(deno --version | grep "deno" | cut -d " " -f 2)
      dvm_print "system (v$deno_version)"
    fi
  }
}

########################
## Command deactivate ##
########################
{
  # Deactivate the active Deno version that added into the global environment
  # variable `PATH` by DVM
  dvm_deactivate() {
    local path_without_dvm

    dvm_get_current_version

    if [ -z "$DVM_DENO_VERSION" ]
    then
      dvm_success
      return
    fi

    path_without_dvm=$(dvm_strip_path)
    export PATH="$path_without_dvm"

    dvm_print "Deno has been deactivated, you can run \"dvm use $DVM_DENO_VERSION\" to restore it."

    unset DVM_DENO_VERSION
  }
}

####################
## Command doctor ##
####################
{
  # Scan the installed versions, and try to finding the invalid versions (the
  # versions from path and Deno `-v` option are not same). It'll try to fix the
  # invalid versions if it run in the `fix` mode.
  # Parameters:
  # $1: the mode of the doctor command.
  dvm_scan_and_fix_versions() {
    local mode
    local raw_output
    local invalid_message
    local corrupted_message
    local version
    local deno_version

    mode="$1"

    if [ ! -d "$DVM_DIR/versions" ]
    then
      return
    fi

    if [ -z "$(ls -A "$DVM_DIR/versions")" ]
    then
      return
    fi

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

  # Try to moving the Deno files to the correct path, and remove it if the
  # version was existed.
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

    dvm_print "Invalid version(s) has been fixed."
  }

  # Print the invalid (versions from file and path are not same) and the
  # corrupted (unable to run) versions.
  # Parameters:
  # $1: invalid versions list.
  # $2: corrupted versions list.
  dvm_print_doctor_message() {
    local invalid_message
    local corrupted_message

    invalid_message="$1"
    corrupted_message="$2"

    if [ -z "$invalid_message" ] && [ -z "$corrupted_message" ]
    then
      dvm_print "Everything is ok."
      return
    fi

    if [ -n "$invalid_message" ]
    then
      dvm_print "Invalid versions:"
      dvm_print "$invalid_message"
    fi

    if [ -n "$corrupted_message" ]
    then
      dvm_print "Corrupted versions:"
      dvm_print "$corrupted_message"
    fi

    dvm_print "You can run \"dvm doctor --fix\" to fix these errors."
  }
}

##################
## Command help ##
##################
{
  # Print help messages.
  dvm_print_help() {
    dvm_print
    dvm_print "Deno Version Manager"
    dvm_print
    dvm_print "Usage:"
    dvm_print "  dvm install [version]             Download and install by version. Install latest or use .dvmrc file if version is omitted."
    dvm_print "    --registry=<registry>           Download and install deno with the specified registry."
    dvm_print "    --skip-validation               Skip version validation before download."
    dvm_print "    --skip-download-cache           Don't use downloaded cache file."
    dvm_print "  dvm uninstall [name|version]      Uninstall a specified version."
    dvm_print "  dvm use [name|version]            Use the specified version that passed by argument or read from .dvmrc."
    dvm_print "  dvm run <name|version> [args]     Run deno on the specified version with arguments."
    dvm_print "  dvm alias <name> <version>        Set an alias name to specified version."
    dvm_print "  dvm unalias <name|version>        Delete the specified alias name."
    dvm_print "  dvm current                       Display the current version of Deno."
    dvm_print "  dvm ls                            List all installed versions."
    dvm_print "  dvm ls-remote                     List all remote versions."
    dvm_print "  dvm which [current|name|version]  Display the path of installed version."
    dvm_print "  dvm clean                         Remove all downloaded packages."
    dvm_print "  dvm deactivate                    Deactivate Deno on current shell."
    dvm_print "  dvm doctor                        Scan installed versions and find invalid / corrupted versions."
    dvm_print "    --fix                           Scan and fix all invalid / corrupted versions."
    dvm_print "  dvm upgrade                       Upgrade dvm itself."
    dvm_print "  dvm purge                         Remove dvm from your computer."
    dvm_print "  dvm help                          Show this message."
    dvm_print
    dvm_print "Options:"
    dvm_print "  -q, --quiet                       Make outputs more quiet."
    dvm_print "  --color                           Print colorful messages."
    dvm_print "  --no-color                        Print messages without color."
    dvm_print "  --verbose                         Run in verbose mode, it'll print debug messages."
    dvm_print
    dvm_print "Note:"
    dvm_print "  <param> is required paramter, [param] is optional paramter."
    dvm_print
    dvm_print "Examples:"
    dvm_print "  dvm install v1.0.0"
    dvm_print "  dvm uninstall v0.42.0"
    dvm_print "  dvm use v1.0.0"
    dvm_print "  dvm alias default v1.0.0"
    dvm_print "  dvm run v1.0.0 app.ts"
    dvm_print
  }
}

#####################
## Command install ##
#####################
{
  # Try to build the binary file of Deno with the specified version, and move
  # the build target file to the versions directory.
  # Parameters:
  # - $1: The Deno version to building.
  dvm_build_deno() {
    local version
    version="$1"

    old_dir=$(pwd)
    cd "$DVM_DIR/deno_code" || return

    git reset --hard HEAD
    if ! git checkout "$version" --recurse-submodules
    then
      dvm_failure
      return
    fi

    cargo clean

    if ! cargo build --release
    then
      dvm_print_error "failed to build deno"
      cd "$old_dir" || return
      dvm_failure
      return
    fi

    if ! dvm_validate_build_target "$version"
    then
      cd "$old_dir" || return
      dvm_failure
      return
    elif ! dvm_copy_build_target_to_versions_dir "$version"
    then
      cd "$old_dir" || return
      dvm_failure
      return
    else
      cargo clean
      cd "$old_dir" || return
    fi
  }

  # Check the dependencies for building Deno from the source code.
  dvm_check_build_dependencies() {
    for command in git rustc cargo cc cmake
    do
      if ! dvm_has "$command"
      then
        dvm_print_error "$command is required"
        dvm_failure
        return
      fi
    done
  }

  # Try to check the local clone of the source code, and fetch the latest data
  # if the local clone is valid. It will delete the source code directory and
  # clone it again later if the directory is not the repo of the Deno source
  # code.
  dvm_check_local_deno_clone() {
    local old_dir

    old_dir=$(pwd)
    cd "$DVM_DIR/deno_code" || return

    ret=$(git remote -v | grep "deno.git")
    if [ -z "$ret" ]
    then
      dvm_print_warning "The local clone of Deno source is invalid, trying to reclone..."
      rm -rf "$DVM_DIR/deno_code"

      cd "$old_dir" || return
      dvm_failure
    else
      # update repo
      git fetch

      cd "$old_dir" || return
    fi
  }

  # Clone the source code of Deno into the local directory, and update the
  # local clone if it was cloned.
  dvm_clone_deno_source() {
    if [ -d "$DVM_DIR/deno_code" ]
    then
      if dvm_check_local_deno_clone
      then
        return
      fi
    fi

    git clone --recurse-submodules https://github.com/denoland/deno.git "$DVM_DIR/deno_code"
  }

  # Move the build output file to the versions file.
  # Parameters:
  # - $1: The Deno version to install.
  dvm_copy_build_target_to_versions_dir() {
    local version

    version="$1"

    if ! [ -d "$DVM_DIR/versions/$version" ]
    then
      mkdir -p "$DVM_DIR/versions/$version"
    fi

    cp "$DVM_DIR/deno_code/target/release/deno" "$DVM_DIR/versions/$version"
  }

  # Download Deno with the specific version from GitHub or the specific
  # registry (specify by `DVM_INSTALL_REGISTRY` variable). It will download
  # Deno to the cache directory, and move it to versions directory after
  # completed.
  # Parameters:
  # - $1: the Deno version to download.
  dvm_download_deno() {
    local version
    local url
    local temp_file
    local registry

    version="$1"

    if [ ! -d "$DVM_DIR/download/$version" ]
    then
      mkdir -p "$DVM_DIR/download/$version"
    fi

    if [ -z "$DVM_INSTALL_REGISTRY" ]
    then
      if ! [[ "$version" < "v1.0.1" ]] || [[ "$version" = "v1.0.0" ]]
      then
        registry="https://dl.deno.land/release"
      else
        registry="https://github.com/denoland/deno/releases/download"
      fi
    else
      registry="$DVM_INSTALL_REGISTRY"
    fi

    dvm_debug "regitry url: $registry"

    url="$registry/$version/$DVM_TARGET_NAME"
    temp_file="$DVM_DIR/download/$version/deno-downloading.$DVM_TARGET_TYPE"

    if dvm_download_file "$url" "$temp_file"
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

    dvm_print_error "failed to download deno $version."
    dvm_failure
  }

  # Extract the Deno compressed file, and add execute permission to the binary
  # file.
  dvm_extract_file() {
    local target_dir

    target_dir="$DVM_DIR/versions/$1"

    dvm_debug "extracting source file: $DVM_DIR/download/$1/deno.$DVM_TARGET_TYPE"
    dvm_debug "extracting target path: $target_dir"

    if [ ! -d "$target_dir" ]
    then
      mkdir -p "$target_dir"
    fi

    case $DVM_TARGET_TYPE in
    "zip")
      if dvm_has unzip
      then
        unzip "$DVM_DIR/download/$1/deno.zip" -d "$target_dir" > /dev/null
      elif [ "$DVM_TARGET_OS" = "Linux" ] && dvm_has gunzip
      then
        gunzip -c "$DVM_DIR/download/$1/deno.zip" > "$target_dir/deno"
        chmod +x "$target_dir/deno"
      else
        dvm_print_error "unzip is required."
        dvm_failure
      fi
      ;;
    "gz")
      if dvm_has gunzip
      then
        gunzip -c "$DVM_DIR/download/$1/deno.gz" > "$target_dir/deno"
        chmod +x "$target_dir/deno"
      else
        dvm_print_error "gunzip is required."
        dvm_failure
      fi
      ;;
    *)
      ;;
    esac
  }

  # Calls GitHub api to getting deno latest release tag name.
  dvm_get_latest_version() {
    # the url of github api
    local latest_url
    # the latest release tag name
    local tag_name

    dvm_print "\ntry to getting deno latest version ..."

    latest_url="https://dl.deno.land/release-latest.txt"

    if ! dvm_request "$latest_url"
    then
      dvm_print_error "failed to getting deno latest version."
      dvm_failure
      return
    fi

    tag_name="$DVM_REQUEST_RESPONSE"

    if [ -z "$tag_name" ]
    then
      dvm_print_error "failed to getting deno latest version."
      dvm_failure
      return
    fi

    dvm_print "Found deno latest version $tag_name"

    DVM_TARGET_VERSION="$tag_name"
    DVM_INSTALL_SKIP_VALIDATION=true
  }

  # Get remote package name by host os and architecture.
  # Parameters:
  # - $1: the deno version to install.
  dvm_get_package_data() {
    local target_version

    DVM_TARGET_OS=$(uname -s)
    DVM_TARGET_ARCH=$(uname -m)
    target_version="$1"

    dvm_debug "target os: $DVM_TARGET_OS"
    dvm_debug "target arch: $DVM_TARGET_ARCH"
    dvm_debug "target deno version: $target_version"

    if [ "$DVM_TARGET_OS" = "Darwin" ] &&
      [ "$DVM_TARGET_ARCH" = 'arm64' ] &&
      dvm_compare_version "$target_version" "v1.6.0"
    then
      dvm_print_error "Mac with M-series chips (aarch64-darwin) support deno v1.6.0 and above versions only."
      dvm_failure
      return
    fi

    if [ "$DVM_TARGET_OS" = "Linux" ] &&
      [ "$DVM_TARGET_ARCH" = 'arm64' ] &&
      dvm_compare_version "$target_version" "v1.40.3"
    then
      dvm_print_error "Linux with ARM64 chips (aarch64-linux) support deno v1.40.3 and above versions only."
      dvm_failure
      return
    fi

    if dvm_compare_version "$target_version" "v0.36.0"
    then
      DVM_TARGET_TYPE="gz"
      DVM_FILE_TYPE="gzip compressed data"
    else
      DVM_TARGET_TYPE="zip"
      DVM_FILE_TYPE="Zip archive data"
    fi

    dvm_debug "target file type: $DVM_TARGET_TYPE"

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
      "Linux:aarch64:zip")
        DVM_TARGET_NAME='deno-aarch64-unknown-linux-gnu.zip'
        ;;
      *"NT"*":x86_64:zip")
        DVM_TARGET_NAME='deno-x86_64-pc-windows-msvc.zip'
        ;;
      *)
        dvm_print_error "unsupported operating system $DVM_TARGET_OS ($DVM_TARGET_ARCH)."
        dvm_failure
        return
        ;;
    esac

    dvm_debug "target file name: $DVM_TARGET_NAME"
  }

  # Gets the latest version with the prefix.
  # Parameters:
  # - $1: the version prefix to search.
  dvm_get_remote_version_by_prefix() {
    local search_text
    local version_prefix
    local tmp_versions

    search_text="$1"
    version_prefix="$search_text"

    dvm_debug "searching version starts with $version_prefix"

    if [[ "$version_prefix" == *"." ]]
    then
      version_prefix="${version_prefix%%.}"
    fi
    version_prefix="$version_prefix\."

    dvm_debug "searching version prefix: $version_prefix"

    if ! dvm_get_remote_versions
    then
      dvm_failure
      return
    fi

    tmp_versions=$(echo "$DVM_REMOTE_VERSIONS" | grep -E "$version_prefix" | tail -n 1)
    if [ -z "$tmp_versions" ]
    then
      dvm_print_error "no version found by $search_text"
      dvm_failure
      return
    fi

    dvm_debug "matched version found $tmp_versions"
    DVM_TARGET_VERSION="$tmp_versions"
    DVM_INSTALL_SKIP_VALIDATION=true
  }

  # Install Deno with the specific version, it'll try to get version from the
  # parameter, .dvmrc file (current directory and home directory), or the
  # latest Deno version.
  # Parameters:
  # - $1: the Deno version to install. (Optional)
  dvm_install_version() {
    local version

    version="$1"

    if [ -z "$version" ]
    then
      if ! dvm_get_version_from_dvmrc && ! dvm_get_latest_version
      then
        return
      fi
    else
      if ! dvm_is_version_prefix "$version"
      then
        return
      fi
    fi
    version="$DVM_TARGET_VERSION"

    if [ -f "$DVM_DIR/versions/$version/deno" ]
    then
      dvm_print "Deno $version has been installed."
      dvm_success
      return
    fi

    if [ "$DVM_INSTALL_SKIP_VALIDATION" = false ]
    then
      if ! dvm_validate_remote_version "$version"
      then
        return
      fi
    fi

    if [[ "$version" != "v"* ]]
    then
      version="v$version"
    fi

    if ! dvm_install_deno "$version"
    then
      dvm_failure
      return
    fi

    dvm_print "Deno $version has installed."

    dvm_use_version "$version"
    dvm_set_default_alias_after_install "$version"
  }

  # Try to install Deno from the network with the binary file, or try to build
  # Deno from the source code.
  # Parameters:
  # - $1: The Deno version to install.
  dvm_install_deno() {
    local version

    version="$1"

    case "$DVM_INSTALL_MODE" in
      "binary")
        if ! dvm_install_deno_by_binary "$version"
        then
          dvm_failure
          return
        fi
        ;;
      "source")
        if ! dvm_install_deno_by_source "$version"
        then
          dvm_failure
          return
        fi
        ;;
      *)
        dvm_print_error "Unknown install mode: $DVM_INSTALL_MODE"
        dvm_failure
        ;;
    esac
  }

  # Download and install the pre-compiled Deno binary file from the network.
  # Parameters:
  # - $1: The Deno version to install.
  dvm_install_deno_by_binary() {
    local version

    version="$1"

    if ! dvm_get_package_data "$version"
    then
      dvm_failure
      return
    fi

    if [ "$DVM_INSTALL_SKIP_CACHE" = true ] || [ ! -f "$DVM_DIR/download/$version/deno.$DVM_TARGET_TYPE" ]
    then
      dvm_print "Downloading and installing deno $version..."
      if ! dvm_download_deno "$version"
      then
        dvm_failure
        return
      fi
    else
      dvm_print "Installing deno $version from cache..."
    fi

    dvm_extract_file "$version"
  }

  # Download the source code of Deno from the network, and try to building the
  # binary file.
  # Parameters:
  # - $1: The Deno version to install.
  dvm_install_deno_by_source() {
    local version
    version="$1"

    if ! dvm_check_build_dependencies
    then
      dvm_failure
      return
    fi

    if ! dvm_clone_deno_source
    then
      dvm_failure
      return
    fi

    dvm_build_deno "$version"
  }

  # Check the version string whether it is a prefix or not.
  # Parameters:
  # - $1: the string to check.
  dvm_is_version_prefix() {
    local result
    local version

    version="$1"
    if [[ "$version" != "v"* ]]
    then
      version="v$version"
    fi

    result=$(echo "$version" | grep -E "^v[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+")
    if [ -z "$result" ]
    then
      dvm_debug "$version is a version prefix"
      if ! dvm_get_remote_version_by_prefix "$version"
      then
        dvm_failure
        return
      fi
    else
      dvm_debug "$version is not a version prefix"
      DVM_TARGET_VERSION="$version"
    fi
  }

  # Try to set the installed version as the alias 'default' if no default set.
  # Parameters:
  # - $1: the Deno version to set to default.
  dvm_set_default_alias_after_install() {
    local version="$1"

    dvm_check_alias_dir

    if [ -f "$DVM_DIR/aliases/default" ]
    then
      return
    fi

    echo "$version" > "$DVM_DIR/aliases/default"
    dvm_print "Creating default alias: default -> $version"
  }

  # Try to validate the build output file.
  # Parameters:
  # - $1: The Deno version to install.
  dvm_validate_build_target() {
    local version
    local target_version

    target_version="$1"

    if ! [ -f "$DVM_DIR/deno_code/target/release/deno" ]
    then
      dvm_print_error "no output found."
      dvm_failure
      return
    fi

    version=$("$DVM_DIR/deno_code/target/release/deno" --version | grep deno | cut -d " " -f 2)
    if [ "v$version" != "$target_version" ]
    then
      dvm_print_error "unmatched build target version v$version"
      dvm_debug "build file version: v$version"
      dvm_debug "target version: $version"
      dvm_failure
      return
    fi
  }

  # Get remote data by GitHub api (Get a release by tag name) to validate the
  # version from the parameter.
  # Parameters:
  # - $1: the version to validate.
  dvm_validate_remote_version() {
    local version
    local target_version
    # GitHub get release by tag name api url
    local tag_url

    version="$1"

    if [[ "$version" != "v"* ]]
    then
      target_version="v$version"
    else
      target_version="$version"
    fi

    dvm_debug "validation target deno version: $version"

    if [ -f "$DVM_DIR/cache/remote-versions" ]
    then
      dvm_debug "remote versions cache found, try to validate version $version"
      if grep "$target_version" < "$DVM_DIR/cache/remote-versions" > /dev/null
      then
        dvm_debug "version $version found in cache"
        return
      fi
      dvm_debug "no version $version found in cache, try to validate from network"
    fi

    tag_url="https://api.github.com/repos/denoland/deno/releases/tags/$target_version"

    if ! dvm_request "$tag_url"
    then
      dvm_print_warning "failed to validating deno version."
    fi

    tag_name=$(echo "$DVM_REQUEST_RESPONSE" | sed 's/"/\n/g' | grep tag_name -A 2 | grep v)

    if [ -z "$tag_name" ]
    then
      if echo "$DVM_REQUEST_RESPONSE" | grep "Not Found" > /dev/null
      then
        dvm_print_error "deno '$version' not found, use 'ls-remote' command to get available versions."
        dvm_failure
      else
        dvm_print_warning "failed to validating deno version."
        dvm_debug "validation response: $DVM_REQUEST_RESPONSE"
      fi
    fi
  }
}

##################
## Command list ##
##################
{
  # List all aliases and get the version of the alias name.
  dvm_list_aliases() {
    local aliased_version

    if [ ! -d "$DVM_DIR/aliases" ]
    then
      return
    fi

    if [ -z "$(ls -A "$DVM_DIR/aliases")" ]
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
      aliased_version=$(head -n 1 "$alias_path")

      if [ -z "$aliased_version" ] ||
        [ ! -f "$DVM_DIR/versions/$aliased_version/deno" ]
      then
        dvm_print "$alias_name -> N/A"
      else
        dvm_print "$alias_name -> $aliased_version"
      fi
    done
  }

  # List all Deno versions that have been installed.
  dvm_list_local_versions() {
    local version

    if [ ! -d "$DVM_DIR/versions" ]
    then
      return
    fi

    if [ -z "$(ls -A "$DVM_DIR/versions")" ]
    then
      return
    fi

    for dir in "$DVM_DIR/versions"/*
    do
      if [ ! -f "$dir/deno" ]
      then
        continue
      fi

      version=${dir##*/}

      if [ "$version" = "$DVM_DENO_VERSION" ]
      then
        dvm_print_with_color "32" "-> $version"
      else
        dvm_print "   $version"
      fi
    done
  }
}

#######################
## Command ls-remote ##
#######################
{
  # Try to get all remote version from the local cache or the remote server.
  dvm_get_remote_versions() {
    local last_version
    local cache_file

    cache_file="$DVM_DIR/cache/remote-versions"

    if [ ! -d "$DVM_DIR/cache" ]
    then
      mkdir "$DVM_DIR/cache"
    fi

    if [ -f "$cache_file" ] && [ "$(head "$cache_file" -n 1)" = "v0.1.0" ]
    then
      if [ "$(find "$cache_file" -mmin -15 2>/dev/null)" ]
      then
        DVM_REMOTE_VERSIONS="$(cat "$cache_file")"
        dvm_debug "remote versions cache found"
        return
      else
        last_version="$(tail -n 1 "$cache_file")"
        if [ -n "$last_version" ]
        then
          if ! dvm_get_latest_version
          then
            return
          fi

          dvm_debug "last version in cache: $last_version"
          dvm_debug "latest version from network: $DVM_TARGET_VERSION"

          if [ "$last_version" = "$DVM_TARGET_VERSION" ]
          then
            DVM_REMOTE_VERSIONS="$(cat "$cache_file")"
            return
          fi
        fi
      fi
    else
      dvm_debug "remote versions cache not found or it's invalid"
    fi

    if ! dvm_get_versions_from_network "$last_version"
    then
      dvm_failure
      return
    fi

    echo "$DVM_REMOTE_VERSIONS" >> "$cache_file"

    # re-read the full remote versions
    DVM_REMOTE_VERSIONS=$(cat "$cache_file")
  }

  # Call GitHub API to getting all versions (release tag names) from the
  # Deno repo.
  # Parameters:
  # - $1: the last version that already fetched (optional).
  dvm_get_versions_from_network() {
    local request_url
    local all_versions
    local size
    local tmp_versions
    local expect_version

    if [ "$#" != "0" ] && [ -n "$1" ]
    then
      expect_version="$1"
    fi

    size=100
    request_url="https://api.github.com/repos/denoland/deno/releases?per_page=$size&page=1"

    while [ "$request_url" != "" ]
    do
      if ! dvm_request "$request_url" "--include"
      then
        dvm_print_error "failed to list remote versions."
        dvm_failure
        return
      fi

      tmp_versions=$(echo "$DVM_REQUEST_RESPONSE" | sed 's/"/\n/g' | grep tag_name -A 2 | grep v)
      all_versions="$all_versions\n$tmp_versions"

      if [ -n "$expect_version" ] && echo "$tmp_versions" | grep "$expect_version" > /dev/null
      then
        all_versions=${all_versions%"${expect_version}"*}
        break
      fi

      request_url=$(echo "$DVM_REQUEST_RESPONSE" | grep -i "link:" | sed 's/,/\n/g' | grep "rel=\"next\"" \
        | sed 's/[<>]/\n/g' | grep "http")
      dvm_debug "list releases next page url: $request_url"
    done

    DVM_REMOTE_VERSIONS=$(echo -e "$all_versions" | sed '/^$/d' | sed 'x;1!H;$!d;x')
  }

  # Get all available versions from network, and list them with installation
  # status.
  dvm_list_remote_versions() {
    if ! dvm_get_remote_versions
    then
      return
    fi

    dvm_get_current_version

    while read -r version
    do
      if [ "$DVM_DENO_VERSION" = "$version" ]
      then
        dvm_print_with_color "32" "-> $version *"
      elif [ -f "$DVM_DIR/versions/$version/deno" ]
      then
        dvm_print_with_color "34" "   $version *"
      else
        dvm_print "   $version"
      fi
    done <<< "$DVM_REMOTE_VERSIONS"
  }
}

###################
## Command purge ##
###################
{
  # Remove all components of DVM from the host.
  dvm_purge_dvm() {
    local content

    # remove DVM directory, all installed versions will also removed.
    rm -rf "$DVM_DIR"

    # get profile file and remove DVM configs.
    dvm_get_profile_file

    content=$(sed "/Deno Version Manager/d;/DVM_DIR/d;/DVM_BIN/d" "$DVM_PROFILE_FILE")
    echo "$content" > "$DVM_PROFILE_FILE"

    # unset global variables
    unset -v DVM_COLOR_MODE DVM_DENO_VERSION DVM_DIR DVM_FILE_TYPE DVM_INSTALL_MODE \
      DVM_INSTALL_REGISTRY DVM_INSTALL_SKIP_CACHE DVM_INSTALL_SKIP_VALIDATION DVM_LATEST_VERSION \
      DVM_PROFILE_FILE DVM_QUIET_MODE DVM_REMOTE_VERSIONS DVM_REQUEST_RESPONSE DVM_SOURCE \
      DVM_TARGET_ARCH DVM_TARGET_NAME DVM_TARGET_OS DVM_TARGET_TYPE DVM_TARGET_VERSION \
      DVM_VERBOSE_MODE DVM_VERSION
    # unset dvm itself
    unset -f dvm
    # unset dvm functions
    unset -f dvm_build_deno dvm_check_alias_dir dvm_check_build_dependencies \
      dvm_check_local_deno_clone dvm_clean_download_cache \
      dvm_clone_deno_source dvm_compare_version dvm_confirm_with_prompt \
      dvm_copy_build_target_to_versions_dir dvm_deactivate dvm_debug \
      dvm_download_deno dvm_download_file dvm_extract_file dvm_failure \
      dvm_fix_invalid_versions dvm_get_current_version \
      dvm_get_dvm_latest_version dvm_get_latest_version dvm_get_package_data \
      dvm_get_profile_file dvm_get_remote_version_by_prefix dvm_get_remote_versions \
      dvm_get_version dvm_get_version_from_dvmrc dvm_get_version_by_param \
      dvm_get_versions_from_network dvm_has dvm_install_deno dvm_install_deno_by_binary \
      dvm_install_deno_by_source dvm_install_version dvm_is_version_prefix dvm_list_aliases \
      dvm_list_local_versions dvm_list_remote_versions dvm_locate_version dvm_parse_options \
      dvm_print dvm_print_doctor_message dvm_print_current_version dvm_print_error \
      dvm_print_help dvm_print_warning dvm_print_with_color dvm_purge_dvm \
      dvm_read_dvmrc_file dvm_request dvm_rm_alias dvm_run_with_version \
      dvm_scan_and_fix_versions dvm_set_alias \
      dvm_set_default_alias_after_install dvm_set_default_env dvm_strip_path \
      dvm_success dvm_uninstall_version dvm_update_dvm dvm_use_version \
      dvm_validate_build_target dvm_validate_remote_version
    # unset dvm shell completion functions
    unset -f _dvm_add_aliases_to_opts _dvm_add_versions_to_opts \
      _dvm_has_active_version _dvm_add_options_to_opts _dvm_completion

    echo "DVM has been removed from your computer."
  }
}

#################
## Command run ##
#################
{
  # Run the Deno of the specific version without activate.
  # Parameters:
  # $1: the version of Deno to be run.
  # $2...: the parameters that passing to the Deno.
  dvm_run_with_version() {
    if [ ! -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
    then
      dvm_print_error "deno $DVM_TARGET_VERSION is not installed."
      dvm_failure
      return
    fi

    dvm_print "Running with deno $DVM_TARGET_VERSION."

    dvm_debug "target deno version: $DVM_TARGET_VERSION"
    dvm_debug "run deno with parameters:" "$@"

    "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" "$@"
  }
}

###################
## Command which ##
###################
{
  # Get the path of the active version or the specific version of Deno.
  # Parameters:
  # $1: the version of Deno, or 'current'.
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
      dvm_print "$DVM_DIR/versions/$target_version/deno"
    else
      dvm_print "Deno $target_version is not installed."
    fi
  }
}

#####################
## Command unalias ##
#####################
{
  # Remove an alias name of a Deno version.
  # Parameters:
  # $1: the alias name to be remove.
  dvm_rm_alias() {
    local alias_name
    local aliased_version

    dvm_check_alias_dir

    while [ "$#" -gt "0" ]
    do
      case "$1" in
      "-"*)
        ;;
      *)
        if [ -z "$alias_name" ]
        then
          alias_name="$1"
        fi
      esac

      shift
    done

    if [ ! -f "$DVM_DIR/aliases/$alias_name" ]
    then
      dvm_print_error "alias $alias_name does not exist."
      dvm_failure
      return
    fi

    aliased_version=$(head -n 1 "$DVM_DIR/aliases/$alias_name")

    rm "$DVM_DIR/aliases/$alias_name"

    dvm_print "Deleted alias $alias_name."
    dvm_print "Restore it with 'dvm alias $alias_name $aliased_version'."
  }
}

#######################
## Command uninstall ##
#######################
{
  # Uninstall the specific version of Deno from the computer. It cannot
  # uninstall the active Deno version or installing from another source.
  # Parameters:
  # - $1: the Deno version to uninstall.
  dvm_uninstall_version() {
    local input_version

    input_version="$1"

    dvm_get_current_version

    if [ "$DVM_DENO_VERSION" = "$DVM_TARGET_VERSION" ]
    then
      dvm_print "Cannot active deno version ($DVM_DENO_VERSION)."
      dvm_failure
      return
    fi

    if [ -f "$DVM_DIR/versions/$DVM_TARGET_VERSION/deno" ]
    then
      rm -rf "$DVM_DIR/versions/$DVM_TARGET_VERSION"

      dvm_print "Uninstalled deno $DVM_TARGET_VERSION."
    else
      dvm_print "Deno $DVM_TARGET_VERSION is not installed."
    fi

    if [ -n "$input_version" ] && [ "$input_version" != "$DVM_TARGET_VERSION" ] && [ -f "$DVM_DIR/aliases/$input_version" ]
    then
      rm "$DVM_DIR/aliases/$input_version"
    fi
  }
}

#####################
## Command upgrade ##
#####################
{
  # Gets the latest version of DVM from the GitHub or Gitee repo.
  dvm_get_dvm_latest_version() {
    local request_url

    case "$DVM_SOURCE" in
    "gitee")
      request_url="https://gitee.com/api/v5/repos/ghosind/dvm/releases/latest"
      ;;
    "github"|*)
      request_url="https://api.github.com/repos/ghosind/dvm/releases/latest"
      ;;
    esac

    dvm_debug "dvm source url: $request_url"

    if ! dvm_request "$request_url"
    then
      dvm_print_error "failed to get the latest DVM version."
      dvm_failure
      return
    fi

    DVM_LATEST_VERSION=$(echo "$DVM_REQUEST_RESPONSE" | sed 's/"/\n/g' | grep tag_name -A 2 | grep v)
    if [ -n "$DVM_LATEST_VERSION" ]
    then
      dvm_debug "dvm latest version: $DVM_LATEST_VERSION"
    else
      dvm_debug "getting dvm latest response: $DVM_REQUEST_RESPONSE"
      dvm_failure
    fi
  }

  # Upgrade the DVM itself to the specific version.
  dvm_update_dvm() {
    local cwd

    cwd=$(pwd)

    dvm_get_profile_file

    if ! cd "$DVM_DIR" 2>/dev/null
    then
      dvm_print_error "failed to update dvm."
      dvm_failure
      return
    fi

    # reset changes if exists
    git reset --hard HEAD
    git fetch
    git checkout "$DVM_LATEST_VERSION"

    dvm_print "DVM has upgrade to latest version, please restart your terminal or run \`source $DVM_PROFILE_FILE\` to apply changes."

    cd "$cwd" || dvm_failure
  }
}

#################
## Command use ##
#################
{
  # Create a symbolic link file to make the specified deno version as active
  # version, the symbolic link is linking to the specified deno executable
  # file.
  # Parameters:
  # - $1: deno version or alias name to use.
  dvm_use_version() {
    # deno executable file version
    local deno_version
    # target deno executable file path
    local target_path
    local path_without_dvm

    dvm_get_version "$@"

    if [ -z "$DVM_TARGET_VERSION" ]
    then
      dvm_print_help
      dvm_failure
      return
    fi

    target_dir="$DVM_DIR/versions/$DVM_TARGET_VERSION"
    target_path="$target_dir/deno"

    if [ -f "$target_path" ]
    then
      # get target deno executable file version
      deno_version=$("$target_path" --version 2>/dev/null | grep deno | cut -d " " -f 2)

      if [ -n "$deno_version" ] && [ "$DVM_TARGET_VERSION" != "v$deno_version" ]
      then
        # print warnning message when deno version is different with parameter.
        dvm_print_warning "You may had upgraded this version, it is v$deno_version now."
      fi

      # export PATH with the target dir in front
      path_without_dvm=$(dvm_strip_path)
      export PATH="$target_dir":${path_without_dvm}

      dvm_print "Using deno $DVM_TARGET_VERSION now."
    else
      dvm_print "Deno $DVM_TARGET_VERSION is not installed, you can run 'dvm install $DVM_TARGET_VERSION' to install it."
      dvm_failure
    fi
  }
}

# The entry of DVM, it will handle options and try to execute commands.
dvm() {
  local version=""

  dvm_set_default_env

  if [ "$#" = "0" ]
  then
    dvm_print_help
    dvm_success
    return
  fi

  dvm_parse_options "$@"

  case "$1" in
  "alias")
    shift

    dvm_set_alias "$@"

    ;;
  "clean")
    # remove all download packages.
    dvm_clean_download_cache

    ;;
  "current")
    # get the current version
    dvm_print_current_version

    ;;
  "deactivate")
    dvm_deactivate

    ;;
  "doctor")
    local mode

    shift

    mode="scan"

    while [ "$#" -gt "0" ]
    do
      case "$1" in
      "--fix")
        mode="fix"
        ;;
      *)
        ;;
      esac

      shift
    done

    if [ "$mode" = "fix" ] &&
      ! dvm_confirm_with_prompt "Doctor fix command will remove all duplicated / corrupted versions, do you want to continue?"
    then
      return
    fi

    dvm_scan_and_fix_versions "$mode"

    ;;
  "install"|"i")
    # install the specified version
    shift

    while [ "$#" -gt "0" ]
    do
      case "$1" in
      "--registry="*)
        DVM_INSTALL_REGISTRY=${1#--registry=}
        ;;
      "--skip-validation")
        DVM_INSTALL_SKIP_VALIDATION=true
        ;;
      "--skip-download-cache")
        DVM_INSTALL_SKIP_CACHE=true
        ;;
      "--from-binary")
        DVM_INSTALL_MODE="binary"
        ;;
      "--from-source")
        DVM_INSTALL_MODE="source"
        ;;
      "-"*)
        ;;
      *)
        version="$1"
        ;;
      esac

      shift
    done

    dvm_install_version "$version"

    ;;
  "list"|"ls")
    # list all local versions
    dvm_get_current_version

    dvm_list_local_versions

    dvm_list_aliases

    ;;
  "list-remote"|"ls-remote")
    # list all remote versions
    dvm_list_remote_versions

    ;;
  "purge")
    if ! dvm_confirm_with_prompt "Do you want to remove DVM from your computer?"
    then
      return
    fi

    if ! dvm_confirm_with_prompt "Remove dvm will also remove installed deno(s), do you want to continue?"
    then
      return
    fi

    dvm_purge_dvm

    ;;
  "run")
    shift

    dvm_get_version "$@"

    if [ "$DVM_TARGET_VERSION" = "" ]
    then
      dvm_print_help
      dvm_failure
      return
    fi

    while [ "$#" != "0" ]
    do
      case "$1" in
      "-"*)
        shift
        ;;
      *)
        shift
        break
        ;;
      esac
    done

    dvm_run_with_version "$@"

    ;;
  "which")
    shift

    dvm_get_version "$@"

    if [ -z "$DVM_TARGET_VERSION" ]
    then
      dvm_print_help
      dvm_failure
      return
    fi

    dvm_locate_version "$@"

    ;;
  "unalias")
    shift

    dvm_rm_alias "$@"

    ;;
  "uninstall")
    # uninstall the specified version
    shift

    dvm_get_version "$@"
    if [ "$DVM_TARGET_VERSION" = "" ]
    then
      dvm_print_help
      dvm_failure
      return
    fi

    dvm_uninstall_version "$DVM_TARGET_VERSION"

    ;;
  "upgrade")
    if ! dvm_get_dvm_latest_version
    then
      return
    fi

    if [ "$DVM_LATEST_VERSION" = "$DVM_VERSION" ]
    then
      dvm_print "dvm is update to date."
      dvm_success
      return
    fi

    dvm_update_dvm

    ;;
  "use")
    # change current version to specified version
    shift

    dvm_use_version "$@"

    ;;
  "help"|"--help"|"-h")
    # print help
    dvm_print_help

    ;;
  "--version")
    # print dvm version
    dvm_print "$DVM_VERSION"

    ;;
  *)
    dvm_print_error "unknown command $1."
    dvm_print_help
    dvm_failure
    ;;
  esac
}

# Activate the default version when a new terminal session was created. It
# need to run in the quiet mode to avoid printing any messages.
if [ -f "$DVM_DIR/aliases/default" ]
then
  DVM_QUIET_MODE=true
  dvm_use_version "default"
  DVM_QUIET_MODE=false
fi

}
