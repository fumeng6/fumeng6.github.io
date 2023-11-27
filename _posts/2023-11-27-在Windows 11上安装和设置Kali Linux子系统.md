---
title: 在Windows 11上安装和设置Kali Linux子系统
date: 2023-11-27 10:00:00 +0800
categories: [编程相关]
tags: [WSL, Kali Linux]
render_with_liquid: false
---

## 在Windows 11上安装Kali Linux子系统

本教程将指导您如何在Windows 11上安装Kali Linux子系统并设置图形启动界面。首先，我们需要启用Windows子系统的Linux功能以及虚拟机平台功能。

### 步骤1：启用Windows子系统的Linux功能

1. 以管理员身份打开PowerShell（开始菜单 > PowerShell > 右键 > 以管理员身份运行）。
2. 输入以下命令并执行：
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```

### 步骤2：启用虚拟机平台功能

1. 在管理员模式下的PowerShell中，运行以下命令：
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```

### 步骤3：安装Linux内核更新包

1. 根据你的系统类型（x64或ARM64），[下载最新的WSL2 Linux内核更新包](https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi)。
2. 运行下载的更新包（双击运行，将提示提升权限，选择“是”以批准此安装）。

### 步骤4：将WSL 2设置为默认版本

1. 打开PowerShell，运行以下命令以将WSL 2设置为安装新Linux发行版时的默认版本：
   ```powershell
   wsl --set-default-version 2
   ```

### 步骤5：安装Kali Linux发行版

1. 打开Microsoft Store，选择[Kali Linux](https://www.microsoft.com/store/apps/9PKR34TNCV07)。
2. 从发行版的页面上，点击“获取”以下载并安装。
3. 第一次启动新安装的Linux发行版时，您将需要创建一个新的用户帐户和密码。

### 步骤6：设置图形启动界面

1. 安装Win-Kex：
```powershell
sudo apt update
sudo apt install -y kali-win-kex
```
安装完成后即可启用kali图形界面，共有三种模式：
- 窗口模式：
![窗口](https://www.kali.org/docs/wsl/win-kex/win-kex-win.png)
   Kali WSL 内部：`kex --win -s`
   
   在 Windows 的命令提示符下：`wsl -d kali-linux kex --win -s`
- 增强会话模式：
![窗口](https://www.kali.org/docs/wsl/win-kex/win-kex-esm.png)
   Kali WSL 内部：`kex --esm --ip -s`

   在 Windows 的命令提示符下：`wsl -d kali-linux kex --esm --ip -s`
- 无缝模式：
![窗口](https://www.kali.org/docs/wsl/win-kex/win-kex-sl.png)

   Kali WSL 内部：`kex --sl -s`

   在 Windows 的命令提示符下：`wsl -d kali-linux kex --sl -s`
2. 在Windows终端中创建快捷启动方式：
从以下选项中进行选择：

- 带声音的窗口模式下的基本 Win-KeX：

```
{
      "guid": "{55ca431a-3a87-5fb3-83cd-11ececc031d2}",
      "hidden": false,
      "name": "Win-KeX",
      "commandline": "wsl -d kali-linux kex --wtstart -s",
},
```
- 带有声音的窗口模式下的高级 Win-KeX - Kali 图标并在 kali 主目录中启动：

   将图标复制到你的 Windows 图片目录，并将图标和启动目录添加到你的Windows Terminal配置中：kali-menu.png
   ```
   {
         "guid": "{55ca431a-3a87-5fb3-83cd-11ececc031d2}",
         "hidden": false,
         "icon": "file:///c:/users/<windows user>/pictures/icons/kali-menu.png",
         "name": "Win-KeX",
         "commandline": "wsl -d kali-linux kex --wtstart -s",
         "startingDirectory" : "//wsl$/kali-linux/home/<kali user>"
   },
   ```
- 带声音的无缝模式下的基本 Win-KeX：
```
{
      "guid": "{55ca431a-3a87-5fb3-83cd-11ececc031d2}",
      "hidden": false,
      "name": "Win-KeX",
      "commandline": "wsl -d kali-linux kex --sl --wtstart -s",
},
```
- 带声音的无缝模式下的高级 Win-KeX - Kali 图标并在 kali 主目录中启动：

   将图标复制到你的 Windows 图片目录，并将图标和启动目录添加到你的Windows Terminal配置中：kali-menu.png
   ```
   {
         "guid": "{55ca431a-3a87-5fb3-83cd-11ececc031d2}",
         "hidden": false,
         "icon": "file:///c:/users/<windows user>/pictures/icons/kali-menu.png",
         "name": "Win-KeX",
         "commandline": "wsl -d kali-linux kex --sl --wtstart -s",
         "startingDirectory" : "//wsl$/kali-linux/home/<kali user>"
   },
   ```
- 增强会话模式下带声音的基本 Win-KeX：
```
{
      "guid": "{55ca431a-3a87-5fb3-83cd-11ecedc031d2}",
      "hidden": false,
      "name": "Win-KeX",
      "commandline": "wsl -d kali-linux kex --esm --wtstart -s",
},
```
- 增强会话模式下的高级 Win-KeX 带声音 - Kali 图标并在 kali 主目录中启动：

   将图标复制到你的 Windows 图片目录，并将图标和启动目录添加到你的Windows Terminal配置中：kali-menu.png
   ```
   {
         "guid": "{55ca431a-3a87-5fb3-83cd-11ecedd031d2}",
         "hidden": false,
         "icon": "file:///c:/users/<windows user>/pictures/icons/kali-menu.png",
         "name": "Win-KeX",
         "commandline": "wsl -d kali-linux kex --esm --wtstart -s",
         "startingDirectory" : "//wsl$/kali-linux/home/<kali user>"
   },
```
### 运行Kali Linux

安装后，您可以通过命令提示符使用`kali`、`wsl --distribution kali-linux`或从开始菜单点击Kali Linux来启动它。

## 迁移子系统

若需要将子系统从默认安装位置迁移至其他位置，可以按如下流程操作：

1. 查看安装的系统
```powershell
wsl -l -v
```
2. 导出kali子系统到D盘压缩文件
```powershell
wsl --export kali-linux D:\kali-linux.tar
```

3. 卸载系统中当前运行的版本
```powershell
wsl --unregister kali-linux
```
4. 重新导入并在指定位置安装kali子系统
```powershell
wsl --import kali-linux D:\WSL\kali-linux D:\kali-linux.tar --version 2
```
5. 设置默认登陆用户为安装时用户名
```powershell
kali-linux config --default-user <username>
```
6. 删除tar文件
```powershell
del D:\kali-linux.tar
wsl -s kali-linux
```

当迁移完毕后，子系统启动时的默认用户会换为`root`账户，如果想改为原本的用户账户，在终端输入如下命令：
```powershell
kali config --default-user <original name>
```