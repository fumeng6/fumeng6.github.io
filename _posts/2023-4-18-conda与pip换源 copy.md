---
title: conda与pip换源
date: 2023-04-18 18:51:58 +0800
categories: [编程相关,Python相关]
tag: [conda,pip]
render_with_liquid: false
---

## Windows下的换源

因为一些原因，使用conda和pip官方源的时候下载速度太慢，可以考虑将它们的源换成国内镜像源。

### conda换源

在windows下，conda的源配置文件是`C:\Users\你的用户名\.condarc`,Windows 用户无法直接创建名为`.condarc`的文件，可先执行下面的这句命令生成该文件之后再修改。

```powershell
conda config --set show_channel_urls yes
```

除此之外，也可以不修改源配置文件，直接通过命令来添加，下面两小节前者使用修改文件的方式换源，后者使用命令的方式来换源。

#### 替换成清华源

将下面的内容复制粘贴进`.condarc`文件并保存。

```text
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```

运行`conda clean -i`清除索引缓存，保证用的是镜像站提供的索引。

运行`conda config --show`查看当前使用的源，确认换源成功。

#### 替换成中科大源

在生成`.condarc`文件后，使用如下命令添加中科大源。

```powershell
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/msys2/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/cloud/menpo/
```

### pip换源

临时换源可用如下命令：

```powershell
pip install [包名] -i https://pypi.tuna.tsinghua.edu.cn/simple
```

永久换源使用如下命令：

```powershell
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

也可以通过修改文件的形式永久换源，pip的源配置文件位于`C:\Users\你的用户名\pip\pip.ini`,只需将如下内容粘贴进去即可：

```text
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
```

## Linux下的换源

Linux下的换源与Windows的基本一致，需要注意的是，Linux系统的conda源配置文件位于`~/.condarc`,而pip的源配置文件在`~/.pip/pip.conf`。
