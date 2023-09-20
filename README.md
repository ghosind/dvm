# DVM - Deno Version Manager

![test](https://github.com/ghosind/dvm/workflows/test/badge.svg)
![lint](https://github.com/ghosind/dvm/workflows/lint/badge.svg)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e11bedd87a194dd6a67140ec447ab51f)](https://www.codacy.com/manual/ghosind/dvm?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ghosind/dvm&amp;utm_campaign=Badge_Grade)
![Version Badge](https://img.shields.io/github/v/release/ghosind/dvm)
![License Badge](https://img.shields.io/github/license/ghosind/dvm)

English | [简体中文](./README-CN.md)

Dvm is a lightweight, and powerful [Deno](https://deno.land/) version manager for MacOS, Linux, WSL, and Windows with Bash.

For Windows users, you must install DVM v0.7.0 or later versions, and also need to install a bash shell if you want to use this tool. For example, you can install WSL and execute `bash` command in PowerShell.

***Please do not use `deno upgrade` command to upgrade Deno after you had installed Deno with DVM.***

- [Installing and Updating](#installing-and-updating)
   - [Installation](#installation)
   - [Upgrade DVM](#upgrade-dvm)
- [Prerequirement](#prerequirement)
- [Getting Started](#getting-started)
  - [List available versions](#list-available-versions)
  - [List installed versions](#list-installed-versions)
  - [Install Deno](#install-deno)
  - [Uninstall Deno](#uninstall-deno)
  - [Set active version](#set-active-version)
  - [Get current version](#get-current-version)
  - [Set an alias](#set-an-alias)
  - [Run with a version](#run-with-a-version)
- [Commands](#commands)
- [Uninstalling DVM](#uninstalling-dvm)
   - [Use `purge` command](#use-purge-command)
   - [Manual uninstall](#manual-uninstall)
- [License](#license)

## Installing and Updating

### Installation

There are two ways to install DVM.

1. Install dvm from network by the following command:

```sh
curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | bash
```

For Chinese user, you can also install it from Gitee by the following command:

```sh
curl -o- "https://gitee.com/ghosind/dvm/raw/master/install.sh" | DVM_SOURCE=gitee bash
```

2. Clone this project and execute `install.sh` script:

```sh
git clone "https://github.com/ghosind/dvm.git"
# you can also clone it from gitee
# git clone "https://gitee.com/ghosind/dvm.git"
cd dvm
./install.sh
```

After installed dvm, please restart your terminal or use `source <your_rc_file>` to apply changes.

The default install location is `~/.dvm`, you can use `-d <dir>` option (for local install only) or `$DVM_DIR` environment variable to specify an inexistent directory as the install location.

```sh
curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | DVM_DIR=~/deno/dvm bash
./install.sh -d ~/deno/dvm
```

### Upgrade DVM

Since DVM `v0.3.0`, we provided `upgrade` command to update your DVM to the latest version.

```sh
dvm upgrade
```

If you want to update the DVM that less than `v0.3.0`, you may need to uninstall the current version and re-install the latest version. You can get the uninstall steps from [Manual uninstall](#manual-uninstall) section.

## Prerequirement

Please make sure you have required dependencies installed:

- curl
- git
- unzip (for Deno v0.36.0 and newer versions)
- gunzip (for Deno v0.35.0 and lower versions)

For installing Deno from source, please make sure you have required dependencies installed:

- rustc
- cargo
- cc
- cmake

## Getting Started

After installed dvm, you can use it to manage multiple version Deno environments.

### List available versions

Use `dvm list-remote` or `dvm ls-remote` to list all available versions from remote.

```sh
# list all available versions
dvm list-remote
# ls-remote is an alias for list-remote command
dvm ls-remote
```

### List installed versions

Use `dvm list` or `dvm ls` to list all installed versions.

```sh
# list all installed versions
dvm list
# ls command is an alias for list command
dvm ls
```

### Install Deno

Use `dvm install <version>` command to download and install a specified version from the source.

```sh
dvm install v1.0.0
# deno v1.0.0 has installed.
# Using deno v1.0.0 now.

dvm install v0.42.0
# deno v0.42.0 has installed.
# Using deno v1.0.0 now.
```

### Install Deno from source

Since DVM v0.8.0, you can install Deno from source with `--from-source` option.

```sh
dvm install --from-source v1.35.0
```

### Uninstall Deno

Use `dvm uninstall <version|alias-name>` command to uninstall a specified version.

```sh
dvm uninstall v0.39.0
# uninstalled deno v0.39.0.

# default is an alias name
dvm uninstall default
# uninstalled deno default.
```

### Set active version

Use `dvm use [version]` command to link `deno` to the specified installed version by parameter or `.dvmrc` file.

```sh
# use v1.0.0
dvm use v1.0.0
# Using deno v1.0.0 now.
```

If you do not specify the active version, DVM will try to read `.dvmrc` file from the current working directory.

```sh
# cat .dvmrc
# # v1.4.0
dvm use
# Found './dvmrc' with version v1.4.0
# Using deno v1.4.0 now.
```

Set active version by `use` command is for a single terminal session only. If you want to set an active version for all terminal sessions, please set a `default` alias to a version. See [Set an alias](#set-active-version) section for more details.

### Get current version

Use `dvm current` command to display the current version of Deno.

```sh
dvm current
# v1.0.0
```

### Set an alias

Use `dvm alias` command to set alias name for a installed version of Deno.

```sh
dvm ls
#    v1.0.0

# Set an alias
dvm alias default v1.0.0
# default -> v1.0.0

dvm ls
#    v1.0.0
# default -> v1.0.0
```

### Run with a version

Use `dvm run` command to run Deno on the specified version with arguments.

```sh
dvm run v1.0.0
# Running with deno v1.0.0
# Deno 1.0.0
# exit using ctrl+d or close()
# >
```

You can also run a script file with the specified version.

```sh
# Run app.ts with Deno v1.0.0
dvm run v1.0.0 app.ts
```

## Commands

DVM supported the following commands:

| Command | Usage | Description |
|:-------:|:-----:|:------------|
| `install` | `dvm install` | Download and install the latest version or the version reading from `.dvmrc` file. |
| | `dvm install <version>` | Download and install the specified version from source. |
| | `dvm install <version> --registry=<registry>` | Download and install deno with the specified registry. |
| | `dvm install <version> --skip-validation` | Do not validate deno version before trying to download it. |
| | `dvm install <version> --from-source` | Build and install Deno from source code. |
| `uninstall` | `dvm uninstall <version>` | Uninstall the specified version. |
| `use` | `dvm use` | Use the specified version read from .dvmrc. |
| | `dvm use <version>` | Use the specified version that passed by argument. |
| | `dvm use <name>` | Use the specified version of the alias name that passed by argument. |
| `run` | `dvm run <version> [args]` | Run deno on the specified version with arguments. |
| `alias` | `dvm alias <name> <version>` | Set an alias name to specified version. |
| `unalias` | `dvm unalias <name>` | Delete the specified alias name. |
| `current` | `dvm current` | Display the current version of Deno. |
| `ls` | `dvm ls` | List all installed versions. |
| `list` | `dvm list` | Same as `ls` command. |
| `ls-remote` | `dvm ls-remote` | List all remote versions. |
| `list-remote` | `dvm list-remote` | Same as `ls-remote` command. |
| `which` | `dvm which` | Display the path of the version that specified in .dvmrc. |
| | `dvm which current` | Display the path of the current version. |
| | `dvm which <version>` | Display the path of specified version. |
| `clean` | `dvm clean` | Remove all downloaded packages. |
| `deactivate` | `dvm deactivate` | Deactivate Deno on current shell. |
| `doctor` | `dvm doctor` | Find invalid / corrupted versions. |
| | `dvm doctor --fix` | Find and fix invalid / corrupted versions. |
| `upgrade` | `dvm upgrade` | Update dvm itself. |
| `purge` | `dvm purge` | Remove dvm from your computer. |
| `help` | `dvm help` | Show dvm help message. |

Please visit [dvm wiki](https://github.com/ghosind/dvm/wiki) for more details.

### Options

| Option | Description |
|:------:|:------------|
| `-q`, `--quiet` | Run DVM with quiet mode, it'll hide most of the outputs. |
| `--color` | Print messages with color mode. |
| `--no-color` | Print messages with no color mode. |
| `--verbose` | Print debug messages. |

## Uninstalling DVM

There are two ways to remove DVM from your computer.

### Use `purge` command

You can execute `dvm purge` to remove dvm from your computer if your dvm version is `v0.3.2` and above. It will remove the `$DVM_DIR` and dvm configurations in shell config file.

If your dvm is less than `v0.3.2`, please following the next section ([Manual uninstall](#manual-uninstall)) to remove DVM.

### Manual uninstall

You can also execute following command to uninstall dvm:

```sh
rm -rf "$DVM_DIR"
```

Edit shell config file (like `.bashrc` or `.zshrc`), and remove the following lines:

```sh
# Deno Version Manager
export DVM_DIR="$HOME/.dvm"
[ -f "$DVM_DIR/dvm.sh" ] && . "$DVM_DIR/dvm.sh"
[ -f "$DVM_DIR/bash_completion" ] && . "$DVM_DIR/bash_completion"
```

## License

Distributed under the MIT License. See LICENSE file for more information.
