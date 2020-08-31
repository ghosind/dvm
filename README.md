# DVM - Deno Version Manager

![shellcheck](https://github.com/ghosind/dvm/workflows/shellcheck/badge.svg)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e11bedd87a194dd6a67140ec447ab51f)](https://www.codacy.com/manual/ghosind/dvm?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ghosind/dvm&amp;utm_campaign=Badge_Grade)
![Version Badge](https://img.shields.io/github/v/release/ghosind/dvm)
![License Badge](https://img.shields.io/github/license/ghosind/dvm)

English | [简体中文](./README-CN.md)

Dvm is an nvm-like version manager for [Deno](https://deno.land/).

- [Installation](#installation)
- [Getting Start](#getting-start)
- [Commands](#commands)
- [Uninstalling DVM](#uninstalling-dvm)
- [Contribution](#contribution)
- [License](#license)

## Installation

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

## Getting Start

After installed dvm, you can use it to manage multiple version Deno environments.

Use `dvm install <version>` command to download and install a specified version from the source.

```sh
$ dvm install v1.0.0
$ dvn install v0.42.0
```

Use `dvm uninstall <version>` command to uninstall a specified version.

```
$ dvm uninstall v0.39.0
$ dvm uninstall v1.0.0-rc
```

Use `dvm use [version]` command to link `deno` to the specified version by parameter or `.dvmrc` file.

```sh
# use v1.0.0
$ dvm use v1.0.0

# get version from .dvmrc file
# $ cat .dvmrc
# # v1.0.0
$ dvm use
```

Use `dvm current` command to display the current version of deno.

```sh
$ dvm current
# v1.0.0
```

Use `dvm ls` command to list all installed versions, and use `dvm ls-remote` to list all available versions from remote.

```sh
# list all installed versions
$ dvm ls
# list is an alias for ls command
$ dvm list

# list all available versions
$ dvm ls-remote
# list-remote is an alias for ls-remote command
$ dvm list-remote
```

Use `dvm run` command to run Deno on the specified version with arguments.

```sh
# Run app.ts with Deno v1.0.0
$ dvm run v1.0.0 app.ts
```

Use `dvm upgrade` command to update dvm itself (Since v0.3.0).

```sh
$ dvm upgrade
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
| `upgrade` | `dvm upgrade` | Update dvm itself. |

## Uninstalling DVM

You can execute following command to uninstall dvm:

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
2. Create your branch. (`git checkout -b features/someFeatures`)
3. Make your changes.
4. Commit your changes. (`git commit -m 'Add some features'`)
5. Push to the branch. (`git push origin features/someFeatures`)
6. Create a new Pull Request.

Please make sure your commits could pass the shellcheck before creating pull request.

## License

Distributed under the MIT License. See LICENSE file for more information.
