---
title: "shadowsocks服务端安装指南"
date: 2022-03-12
tags: [shadowsocks, vpn]
---

> 官方地址：
>
> [shadowsocks/shadowsocks-libev: Bug-fix-only libev port of shadowsocks. Future development moved to shadowsocks-rust (github.com)](https://github.com/shadowsocks/shadowsocks-libev)
>
> 旧地址，不再更新：
>
> [shadowsocks/shadowsocks at master (github.com)](https://github.com/shadowsocks/shadowsocks/tree/master)
>
> [clowwindy/shadowsocks-libev at master (github.com)](https://github.com/clowwindy/shadowsocks-libev/tree/master)
>

本文基于Ubuntu。

## install

```shell
$ sudo apt install shadowsocks-libev
...
Created symlink /etc/systemd/system/multi-user.target.wants/shadowsocks-libev.service → /lib/systemd/system/shadowsocks-libev.service.
```

## Configuration

> [官方文档](https://github.com/shadowsocks/shadowsocks-libev#configure-and-start-the-service)说配置文件在这里：
>
> Edit your config.json file. By default, it's located in /usr/local/etc/shadowsocks-libev.
>
> 但我的不是。
>

编辑`/etc/shadowsocks-libev/config.json`

```shell
{
    "server":"0.0.0.0",
    "mode":"tcp_and_udp",
    "server_port":your-port,
    "password":"your-pass",
    "timeout":300,
    "method":"chacha20-ietf-poly1305"
}
```

mode有三种：tcp_only，udp_only，tcp_and_udp。

"server":"0.0.0.0" //只使用ipv4

"server":["::0","0.0.0.0"] //使用ipv6和ipv4

server-port: 这个端口我之前用的443，因为公司网络只给了80和443出口。但是用443的时候很慢或者根本翻不出去，v2RayN日志如下：

> app/proxyman/outbound: failed to process outbound traffic > proxy/shadowsocks: failed to find an available destination > common/retry: [dial tcp x.x.x.x:443: i/o timeout dial tcp x.x.x.x:443: operation was canceled] > common/retry: all retry attempts failed
>

换成别的端口如8888就可以了。80没试。

> 默认的 `"server":["::1", "127.0.0.1"]`不行。
>
> 删掉了`"local_port":1080`，服务端不需要。
>

## 加速

Using TCP BBR[^1]

```shell
echo net.core.default_qdisc=fq >> /etc/sysctl.conf
echo net.ipv4.tcp_congestion_control=bbr >> /etc/sysctl.conf
sysctl -p
sysctl net.ipv4.tcp_available_congestion_control
```

## 开机启动

```shell
sudo systemctl enable shadowsocks-libev.service
# 禁用开机启动
sudo systemctl disable shadowsocks-libev.service
```

> 官方文档做法：
>
> To enable shadowsocks-libev, add the following rc variable to your `/etc/rc.conf` file:
>
> ```
> shadowsocks_libev_enable="YES"
> ```
>

## Run

Start the Shadowsocks server:

```shell
systemctrl start shadowsocks-libev.service
# 或者
service shadowsocks-libev start
```

## 提示

shadowsocks的服务器在v2rayNG app上无法使用，需使用Shadowsocks app。但是PC上的v2rayN可以使用ss服务器。


[^1]: ### Using TCP BBR

    TCP BBR is a TCP congestion control algorithm developed by Google and its been reported to improve performance on certain networks. You can enable it by adding the following to lines to your system configuration file.
    
    ```
    sudo nano /etc/sysctl.conf
    ```
    
    ```
    net.core.default_qdisc=fq
    net.ipv4.tcp_congestion_control=bbr
    ```
    
    Then save the file and reload the settings.
    
    ```
    sudo sysctl -p
    ```
    
    Check the changes by running the next command.
    
    ```
    sudo sysctl net.ipv4.tcp_congestion_control
    ```
    
    If the output is as follows the setting was applied successfully.
    
    ```
    net.ipv4.tcp_congestion_control = bbr
    ```
    
    These optimisations should help alleviate any possible performance issues.
