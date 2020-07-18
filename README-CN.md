# DVM - Deno Version Manager

![shellcheck](https://github.com/ghosind/dvm/workflows/shellcheck/badge.svg)

简体中文 | [English](./README.md)

DVM是一个类似于[NVM](https://github.com/nvm-sh/nvm)的[Deno](https://deno.land/)版本管理工具。

## 安装

DVM提供了两种安装方式：

1. 运行下列命令通过网络安装DVM：

```sh
$ curl -o- https://raw.githubusercontent.com/ghosind/dvm/master/install.sh | bash
```

2. 下载release包，解压后运行`install.sh`脚本：

```sh
Download/dvm $ ./install.sh
```

## DVM入门

使用`dvm install <version>`下载并安装指定版本：

```sh
$ dvm install v1.0.0
$ dvn install v0.42.0
```

使用`dvm uninstall <version>`卸载指定版本：

```
$ dvm uninstall v0.39.0
$ dvm uninstall v1.0.0-rc
```

使用`dvm use [version]`命令将指定的版本设置为当前使用的版本，若未指定则将从当前目录下的`.dvmrc`文件中读取：

```sh
# 使用Deno v1.0.0
$ dvm use v1.0.0

# 使用通过.dvmrc文件指定的版本
# $ cat .dvmrc
# # v1.0.0
$ dvm use
```

使用`dvm current`命令输出当前使用的Deno版本信息：

```sh
$ dvm current
# v1.0.0
```

使用`dvm ls`命令列出所有已安装的版本（及别名），使用`dvm ls-remote`脚本列出所有可安装的版本：

```sh
# 列除所有当前已安装的版本
$ dvm ls
# 列出所有可安装的版本
$ dvm ls-remote
```

通过`dvm run`命令运行指定版本Deno，在有参数指定的情况下通过对应的参数执行对应的脚本：

```sh
# 使用Deno v1.0.0运行app.ts
$ dvm run v1.0.0 app.ts
```

## 如何卸载DVM

DVM所有的文件都保存在`$DVM_DIR`变量指定的目录下，若需要卸载DVM，只需删除`$DVM_DIR`指定的目录即可。

```sh
rm -rf "$DVM_DIR"
```

### 移除环境配置信息（可选操作）

除文件目录外，DVM将配置信息写入了Shell环境配置文件中（如`.bashrc`或`.zshrc`，根据具体使用的Shell种类决定），您可编辑对应的文件删除下列几行代码：

```sh
# Deno Version Manager
export DVM_DIR="$HOME/.dvm"
export DVM_BIN="$DVM_DIR/bin"
export PATH="$PATH:$DVM_BIN"
[ -f "$DVM_DIR/dvm.sh" ] && alias dvm="$DVM_DIR/dvm.sh"
```

## DVM命令

DVM支持的命令包括有：

| 命令 | 使用方法 | 描述 |
|:-------:|:-----:|:-----------:|
| `install` | `dvm install <version>` | 下载并安装指定的版本 |
| `uninstall` | `dvm uninstall <version>` | 卸载指定的版本 |
| `use` | `dvm use` | 将指定的版本设置为当前使用的版本，未指定版本将从当前目录下的`.dvmrc`文件中读取 |
| | `dvm use <version>` | 将指定的版本设置为当前使用的版本 |
| | `dvm use <name>` | 将指定的别名对应的版本设置为当前使用的版本 |
| `run` | `dvm run <version> [args]` | 运行指定版本Deno，并传递对应的参数 |
| `alias` | `dvm alias <name> <version>` | 为指定版本设置别名 |
| `unalias` | `dvm unalias <name>` | 删除指定的别名 |
| `current` | `dvm current` | 显示当前使用的Deno版本 |
| `ls` | `dvm ls` | 显示所有当前已安装的版本及别名 |
| `list` | `dvm list` | 与`ls`相同 |
| `ls-remote` | `dvm ls-remote` | 显示所有可安装的版本 |
| `list-remote` | `dvm list-remote` | 与`ls-remote`相同 |
| `which` | `dvm which` | 显示指定版本Deno安装的目录，未指定版本将从当前目录下的`.dvmrc`文件中读取 |
| | `dvm which current` | 显示当前使用的版本Deno安装的目录 |
| | `dvm which <version>` | 显示指定版本Deno安装的目录 |
| `clean` | `dvm clean` | 清除下载缓存 |

## 参与项目

1. Fork dvm项目。 ([https://github.com/ghosind/dvm](https://github.com/ghosind/dvm))
2. 创建新的分支。 (`git checkout -b features/someFeatures`)
3. 上传对应的修改。 (`git commit -m 'Add some features'`)
4. 上传至远程仓库。 (`git push origin features/someFeatures`)
5. 创建Pull Request。

## 许可

本项目通过MIT许可发布，查看LICENSE文件获取更多信息。
