# DVM - Deno Version Manager

![dvm](https://github.com/ghosind/dvm/workflows/dvm/badge.svg)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e11bedd87a194dd6a67140ec447ab51f)](https://www.codacy.com/manual/ghosind/dvm?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ghosind/dvm&amp;utm_campaign=Badge_Grade)
[![codecov](https://codecov.io/gh/ghosind/dvm/branch/master/graph/badge.svg)](https://codecov.io/gh/ghosind/dvm)
![Version Badge](https://img.shields.io/github/v/release/ghosind/dvm)
![License Badge](https://img.shields.io/github/license/ghosind/dvm)

English | [简体中文](./README-CN.md)

Dvm is an nvm-like version manager for [Deno](https://deno.land/).

***Please avoid use `deno upgrade` command to upgrade Deno when you're using DVM to manage your multiple version environment.***

- [Installing and Updating](#installing-and-updating)
   - [Installation](#installation)
   - [Upgrade DVM](#upgrade-dvm)
- [Getting Start](#getting-start)
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
- [Contribution](#contribution)
- [License](#license)

## Installing and Updating

### Installation

There are two ways to install DVM.

1. Install dvm from network by the following command:

```sh
$ curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | bash
```

For Chinese user, you can also install it from Gitee by the following command:

```sh
$ curl -o- "https://gitee.com/ghosind/dvm/raw/master/install.sh" | bash -s -r gitee
```

2. Clone this project and execute `install.sh` script:

```sh
$ git clone "https://github.com/ghosind/dvm.git"
# you can also clone it from gitee
# git clone "https://gitee.com/ghosind/dvm.git"
$ cd dvm
$ ./install.sh
```

After installed dvm, please restart your terminal or use `source <your_rc_file>` to apply changes.

The default install location is `~/.dvm`, you can specify an inexistent directory as the install location.

```sh
$ curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | bash -s -d ~/deno/dvm
$ ./install.sh ~/deno/dvm
```

### Upgrade DVM

Since DVM `v0.3.0`, we provided `upgrade` command to update your DVM to the latest version.

```sh
$ dvm upgrade
```

If you want to update the DVM that less than `v0.3.0`, you may need to uninstall the current version and re-install the latest version. You can get the uninstall steps from [Manual uninstall](#manual-uninstall) section.

## Getting Start

After installed dvm, you can use it to manage multiple version Deno environments.

### List available versions

Use `dvm list-remote` or `dvm ls-remote` to list all available versions from remote.

```sh
# list all available versions
$ dvm list-remote
# ls-remote is an alias for list-remote command
$ dvm ls-remote
```

### List installed versions

Use `dvm list` or `dvm ls` to list all installed versions.

```sh
# list all installed versions
$ dvm list
# ls command is an alias for list command
$ dvm ls
```

### Install Deno

Use `dvm install <version>` command to download and install a specified version from the source.

```sh
$ dvm install v1.0.0
deno v1.0.0 has installed.
$ dvn install v0.42.0
deno v0.42.0 has installed.
```

### Uninstall Deno

Use `dvm uninstall <version|alias-name>` command to uninstall a specified version.

```sh
$ dvm uninstall v0.39.0
uninstalled deno v0.39.0.
# default is an alias name
$ dvm uninstall default
uninstalled deno default.
```

### Set active version

Use `dvm use [version]` command to link `deno` to the specified installed version by parameter or `.dvmrc` file.

```sh
# use v1.0.0
$ dvm use v1.0.0
using deno v1.0.0 now.

# get version from .dvmrc file
# $ cat .dvmrc
# # v1.4.0
$ dvm use
using deno v1.4.0 now.
```

### Get current version

Use `dvm current` command to display the current version of Deno.

```sh
$ dvm current
v1.0.0
```

### Set an alias

Use `dvm alias` command to set alias name for a installed version of Deno.

```sh
$ dvm ls
   v1.0.0
# Set an alias
$ dvm alias default v1.0.0
default -> v1.0.0
$ dvm ls
   v1.0.0
default -> v1.0.0
```

### Run with a version

Use `dvm run` command to run Deno on the specified version with arguments.

```sh
$ dvm run v1.0.0
Running with deno v1.0.0
Deno 1.0.0
exit using ctrl+d or close()
>
# Run app.ts with Deno v1.0.0
$ dvm run v1.0.0 app.ts
```

## Commands

DVM supported the following commands:

| Command | Usage | Description |
|:-------:|:-----:|:-----------:|
| `install` | `dvm install <version>` | Download and install the specified version from source.|
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
| `doctor` | `dvm doctor` | Find corrupted versions. |
| `upgrade` | `dvm upgrade` | Update dvm itself. |
| `purge` | `dvm purge` | Remove dvm from your computer. |

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
export DVM_BIN="$DVM_DIR/bin"
export PATH="$PATH:$DVM_BIN"
[ -f "$DVM_DIR/dvm.sh" ] && alias dvm="$DVM_DIR/dvm.sh"
[ -f "$DVM_DIR/bash_completion" ] && . "$DVM_DIR/bash_completion"
```

## Contribution

1. Fork dvm project. ([https://github.com/ghosind/dvm](https://github.com/ghosind/dvm))
2. Clone your fork to local. (`git clone <your_forked_repo>`)
3. Create your branch. (`git checkout -b features/someFeatures`)
4. Make your changes.
5. Commit your changes. (`git commit -m 'Add some features'`)
6. Push to the branch. (`git push origin features/someFeatures`)
7. Create a new Pull Request.

Please make sure your commits could pass the ShellCheck before creating pull request.

## License

Distributed under the MIT License. See LICENSE file for more information.
