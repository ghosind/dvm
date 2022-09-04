# DVM - Deno Version Manager

![test](https://github.com/ghosind/dvm/workflows/test/badge.svg)
![lint](https://github.com/ghosind/dvm/workflows/lint/badge.svg)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/e11bedd87a194dd6a67140ec447ab51f)](https://www.codacy.com/manual/ghosind/dvm?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ghosind/dvm&amp;utm_campaign=Badge_Grade)
![Version Badge](https://img.shields.io/github/v/release/ghosind/dvm)
![License Badge](https://img.shields.io/github/license/ghosind/dvm)

简体中文 | [English](./README.md)

DVM是一个强大的轻量级[Deno](https://deno.land/)版本管理工具。

***在使用DVM管理你的多版本环境时，请避免使用`deno upgrade`命令进行升级deno版本。***

- [安装与升级](#安装与升级)
    - [安装DVM](#安装DVM)
    - [升级DVM](#升级DVM)
- [DVM入门](#DVM入门)
    - [列出可安装版本](#列出可安装版本)
    - [列出已安装的版本](#列出已安装的版本)
    - [安装版本](#安装版本)
    - [删除版本](#删除版本)
    - [切换版本](#切换版本)
    - [当前版本信息](#当前版本信息)
    - [设置别名](#设置别名)
    - [运行指定版本](#运行指定版本)
- [DVM命令](#DVM命令)
- [如何卸载DVM](#如何卸载DVM)
    - [使用`purge`命令](#使用purge命令)
    - [手工卸载](#手工卸载)
- [参与项目](#参与项目)
- [许可](#许可)

## 安装与升级

### 安装DVM

我们提供了以下两种方式以安装DVM：

1. 运行下列命令从网络安装DVM：

```sh
curl -o- https://raw.githubusercontent.com/ghosind/dvm/master/install.sh | bash
```

对于国内的用户，可使用DVM的Gitee镜像以提高下载速度：

```sh
curl -o- https://gitee.com/ghosind/dvm/raw/master/install.sh | DVM_SOURCE=gitee bash
```

2. Clone远程git仓库至本地，并运行`install.sh`脚本：

```sh
git clone "https://github.com/ghosind/dvm.git"
# 同样，可以从我们的gitee项目上clone
# git clone "https://gitee.com/ghosind/dvm.git"
cd dvm
./install.sh
```

在完成DVM的安装后，请重启终端或运行`source <Shell_配置文件>`以应用更改，安装程序将会提醒具体的操作步骤。

默认情况下，DVM将安装在`~/.dvm`目录下，可使用`-d <dir>`参数（仅限于本地安装使用）或`$DVM_DIR`环境变量指定一个不存在的目录作为DVM的安装目录。

```sh
curl -o- "https://raw.githubusercontent.com/ghosind/dvm/master/install.sh" | DVM_DIR=~/deno/dvm bash
./install.sh -d ~/deno/dvm
```

### 升级DVM

若您使用DVM `v0.3.0`及以上版本，可通过DVM本身提供的`upgrade`命令将本地DVM升级至最新的稳定版本。

```sh
dvm upgrade
```

若您使用DVM `v0.3.0`以下的版本时，需要卸载现有版本并重新安装的方法进行升级。您可通过[手工卸载](#手工卸载)章节提供的卸载方式卸载DVM，再重新进行安装。

## DVM入门

### 列出已安装的版本

使用`dvm ls`命令列出所有已安装的版本（及别名）：

```sh
# 列除所有当前已安装的版本
dvm ls
```

### 列出可安装版本

使用`dvm ls-remote`脚本列出所有可安装的版本：

```sh
# 列出所有可安装的版本
dvm ls-remote
```

### 安装版本

使用`dvm install <version>`下载并安装指定版本：

```sh
dvm install v1.0.0
dvn install v0.42.0
```

### 删除版本

使用`dvm uninstall <version>`卸载指定版本：

```
dvm uninstall v0.39.0
dvm uninstall v1.0.0-rc
```

### 切换版本

使用`dvm use [version]`命令将指定的版本设置为当前使用的版本，若未指定则将从当前目录下的`.dvmrc`文件中读取：

```sh
# 使用Deno v1.0.0
dvm use v1.0.0

# 使用通过.dvmrc文件指定的版本
# cat .dvmrc
# # v1.0.0
dvm use
```

### 当前版本信息

使用`dvm current`命令输出当前使用的Deno版本信息：

```sh
dvm current
# v1.0.0
```

### 设置别名

使用`dvm alias`命令可为已安装的版本设置别名：

```sh
dvm alias default v1.0.0
```

### 运行指定版本

通过`dvm run`命令运行指定版本Deno，在有参数指定的情况下通过对应的参数执行对应的脚本：

```sh
# 使用Deno v1.0.0运行app.ts
dvm run v1.0.0 app.ts
```

## DVM命令

DVM支持的命令包括有：

| 命令 | 使用方法 | 描述 |
|:-------:|:-----:|:------------|
| `install` | `dvm install` | 下载并安装从`.dvmrc`读取的指定版本或最新deno版本 |
| | `dvm install <version>` | 下载并安装指定的版本 |
| | `dvm install <version> --registry=<registry>` | 通过指定的镜像下载deno |
| | `dvm install <version> --skip-validation` | 下载deno前不对版本进行校验 |
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
| `deactivate` | `dvm deactivate` | 取消当前shell中活跃的Deno |
| `doctor` | `dvm doctor` | 列出存在问题的版本（未安装成功/版本号错误） |
| | `dvm doctor --fix` | 扫描并修复存在问题的版本 |
| `upgrade` | `dvm upgrade` | 更新DVM |
| `purge` | `dvm purge` | 卸载DVM |
| `help` | `dvm help` | 打印帮助信息 |

更多信息请参考[dvm wiki](https://github.com/ghosind/dvm/wiki)。

### 可选参数

| 参数 | 描述 |
|:------:|:------------|
| `-q`, `--quiet` | 安静模式，大大减少输出的数量，只保留了少数必要的输出 |
| `--color` | 以色彩模式运行，输出的文本不再单调 |
| `--no-color` | 以默认颜色输出 |
| `--verbose` | 打印debug信息 |

## 如何卸载DVM

### 使用`purge`命令

DVM `v0.3.2`及以上版本提供了`purge`命令，该命令可被用于卸载DVM本身，它将移除DVM所在的目录以及Shell环境配置文件中的相关内容。若您的DVM版本低于`v0.3.2`，请通过下面手工卸载的方法卸载。

### 手工卸载

DVM所有的文件都保存在`$DVM_DIR`变量指定的目录下，若需要卸载DVM，只需删除`$DVM_DIR`指定的目录即可。

```sh
rm -rf "$DVM_DIR"
```

除文件目录外，DVM将配置信息写入了Shell环境配置文件中（如`.bashrc`或`.zshrc`，根据具体使用的Shell种类决定），您可编辑对应的文件删除下列几行代码：

```sh
# Deno Version Manager
export DVM_DIR="$HOME/.dvm"
export PATH="$PATH:$DVM_BIN"
[ -f "$DVM_DIR/dvm.sh" ] && . "$DVM_DIR/dvm.sh"
[ -f "$DVM_DIR/bash_completion" ] && . "$DVM_DIR/bash_completion"
```

## 参与项目

1. Fork dvm项目。 ([https://github.com/ghosind/dvm](https://github.com/ghosind/dvm))
2. 下载项目代码至本地。(`git clone <your_forked_repo>`)
3. 创建新的分支。 (`git checkout -b features/someFeatures`)
4. 修改代码。
5. 上传对应的修改。 (`git commit -m 'Add some features'`)
6. 上传至远程仓库。 (`git push origin features/someFeatures`)
7. 创建Pull Request。

请在提交PR前确保你的修改能通过ShellCheck的检查。

## 许可

本项目通过MIT许可发布，查看LICENSE文件获取更多信息。
