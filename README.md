# DVM - Deno Version Manager

![test](https://github.com/ghosind/dvm/workflows/test/badge.svg)
![lint](https://github.com/ghosind/dvm/workflows/lint/badge.svg)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e11bedd87a194dd6a67140ec447ab51f)](https://www.codacy.com/manual/ghosind/dvm?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ghosind/dvm&amp;utm_campaign=Badge_Grade)
![Version Badge](https://img.shields.io/github/v/release/ghosind/dvm)
![License Badge](https://img.shields.io/github/license/ghosind/dvm)

English | [简体中文](./README-CN.md)

DVM is a lightweight and powerful [Deno](https://deno.land/) version manager for macOS, Linux, WSL, and Windows with Bash.

**Note for Windows users:** You must install DVM v0.7.0 or later, and you also need a Bash shell to use this tool. For example, you can install WSL and run the `bash` command in PowerShell.

> [!Warning]
> Do not use the `deno upgrade` command to upgrade Deno after you have installed Deno with DVM.

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

1. Install DVM from the network using the following command:

```sh
curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | bash
```

For users in China, you can install DVM from Gitee using the following command:

```sh
curl -o- "https://gitee.com/ghosind/dvm/raw/master/install.sh" | DVM_SOURCE=gitee bash
```

2. Clone this project and execute the `install.sh` script:

```sh
git clone "https://github.com/ghosind/dvm.git"
# you can also clone it from gitee
# git clone "https://gitee.com/ghosind/dvm.git"
cd dvm
./install.sh
```

After installing DVM, restart your terminal or run `source <your_profile_file>` to apply the changes.

The default installation location is `~/.dvm`. You can use the `-d <dir>` option (for local installs only) or the `$DVM_DIR` environment variable to specify a different directory.

```sh
curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | DVM_DIR=~/deno/dvm bash
./install.sh -d ~/deno/dvm
```

### Upgrade DVM

Since DVM `v0.3.0`, the `upgrade` command is available to update DVM to the latest version.

```sh
dvm upgrade
```

If you are using a DVM version older than `v0.3.0`, you may need to uninstall the current version and reinstall the latest one. See the [Manual uninstall](#manual-uninstall) section for instructions.

## Prerequisites

Please ensure you have the following dependencies installed:

- curl
- git
- unzip (for Deno v0.36.0 and newer versions)
- gunzip (for Deno v0.35.0 and lower versions)

To install Deno from source, you will also need:

- rustc
- cargo
- cc
- cmake

## Getting Started

After installing DVM, you can use it to manage multiple Deno versions and environments.

### List available versions

Use `dvm list-remote` or `dvm ls-remote` to list all available Deno versions from the remote server.

```sh
# list all available versions
dvm list-remote
# ls-remote is an alias for list-remote command
dvm ls-remote
```

### List installed versions

Use `dvm list` or `dvm ls` to list all installed Deno versions.

```sh
# list all installed versions
dvm list
# ls command is an alias for list command
dvm ls
```

### Install Deno

Use the `dvm install <version>` command to download and install a specific Deno version.

```sh
dvm install v1.0.0
# Deno v1.0.0 has been installed.
# Using Deno v1.0.0 now.
dvm install v0.42.0
# Deno v0.42.0 has been installed.
# Using Deno v1.0.0 now.
```

### Install Deno from source

Since DVM v0.8.0, you can install Deno from source using the `--from-source` option.

```sh
dvm install --from-source v1.35.0
```

### Uninstall Deno

Use the `dvm uninstall <version|alias-name>` command to uninstall a specific version or alias.

```sh
dvm uninstall v0.39.0
# Uninstalled Deno v0.39.0.
# default is an alias name
dvm uninstall default
# Uninstalled Deno default.
```

### Set active version

Use the `dvm use [version]` command to link `deno` to the specified installed version, either by parameter or from a `.dvmrc` file.

```sh
# Use v1.0.0
dvm use v1.0.0
# Using Deno v1.0.0 now.
```

If you do not specify a version, DVM will try to read the `.dvmrc` file from the current working directory.

```sh
# cat .dvmrc
# # v1.4.0
dvm use
# Found './dvmrc' with version v1.4.0
# Using Deno v1.4.0 now.
```

Setting the active version with the `use` command only affects the current terminal session. To set a default version for all terminal sessions, create a `default` alias. See the [Set an alias](#set-active-version) section for more details.

### Get current version

Use the `dvm current` command to display the currently active Deno version.

```sh
dvm current
# v1.0.0
```

### Set an alias

Use the `dvm alias` command to set an alias for an installed Deno version.

```sh
dvm ls
#    v1.0.0
# Set the default alias
dvm alias default v1.0.0
# default -> v1.0.0
dvm ls
#    v1.0.0
# default -> v1.0.0
```

### Run with a version

Use the `dvm run` command to run Deno with the specified version and arguments.

```sh
dvm run v1.0.0
# Running with deno v1.0.0
# Deno 1.0.0
# exit using ctrl+d or close()
# >
```

You can also run a script file with the specified Deno version.

```sh
# Run app.ts with Deno v1.0.0
dvm run v1.0.0 app.ts
```

## Commands

DVM supports the following commands:

| Command | Usage | Description |
|:-------:|:-----:|:------------|
| `install` | `dvm install` | Download and install the latest version or the version reading from `.dvmrc` file. |
| | `dvm install <version \| prefix>` | Download and install the specified version, or the latest version with the specified prefix. |
| | `dvm install <version> --registry=<registry>` | Download and install deno with the specified registry. |
| | `dvm install <version> --skip-validation` | Do not validate deno version before trying to download it. |
| | `dvm install <version> --from-source` | Build and install Deno from source code. |
| | `dvm install <version> --skip-download-cache` | Download and install Deno without using downloaded cache. |
| | `dvm install <version> --sha256sum` | Download and install Deno with sha256sum check. |
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
| `clean` | `dvm clean` | Remove all downloaded packages and the cached versions. |
| `deactivate` | `dvm deactivate` | Deactivate Deno on current shell. |
| `doctor` | `dvm doctor` | Find invalid / corrupted versions. |
| | `dvm doctor --fix` | Find and fix invalid / corrupted versions. |
| `upgrade` | `dvm upgrade` | Update dvm itself. |
| `purge` | `dvm purge` | Remove dvm from your computer. |
| `help` | `dvm help` | Show dvm help message. |

For more details, please visit the [DVM Wiki](https://github.com/ghosind/dvm/wiki).

### Options

| Option | Description |
|:------:|:------------|
| `-q`, `--quiet` | Run DVM with quiet mode, it'll hide most of the outputs. |
| `--color` | Print messages with color mode. |
| `--no-color` | Print messages with no color mode. |
| `--verbose` | Print debug messages. |

## Uninstalling DVM

You can remove DVM from your computer in two ways:

### Use `purge` command

You can run `dvm purge` to remove DVM from your computer if your DVM version is `v0.3.2` or above. This will remove the `$DVM_DIR` and DVM configuration from your shell config file.

If your DVM version is older than `v0.3.2`, please follow the next section ([Manual uninstall](#manual-uninstall)) to remove DVM.

### Manual uninstall

Alternatively, you can run the following command to uninstall DVM:

```sh
rm -rf "$DVM_DIR"
```

Edit your shell config file (such as `.bashrc` or `.zshrc`) and remove the following lines:

```sh
# Deno Version Manager
export DVM_DIR="$HOME/.dvm"
[ -f "$DVM_DIR/dvm.sh" ] && . "$DVM_DIR/dvm.sh"
[ -f "$DVM_DIR/bash_completion" ] && . "$DVM_DIR/bash_completion"
```

## License

Distributed under the MIT License. See the LICENSE file for more information.
