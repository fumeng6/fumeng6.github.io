---
title: matplotlib绘图显示中文字符
date: 2023-09-19 16:17:30 +0800
categories: [编程相关,Python相关]
tag: [pyhton绘图]
render_with_liquid: false
---

## matplotlib显示中文字符

在使用python＋matplotlib绘图时总是遇到想要显示中文字符的情况，一般有两种解决方法：

- 在代码中修改

```python
plt.rcParams["font.family"] = ["Microsoft YaHei"]  # 指定字体为微软雅黑
```

此方法仅适用于当前程序中的图形，并非永久修改，比如一旦重启Jupyter的服务后，需要重新执行全局修改声明。

- 在配置文件中修改

首先，运行如下代码：

```python
import matplotlib
print(matplotlib.matplotlib_fname())
```

如此可以获得Matplotlib的配置文件matplotlibrc的位置，在其中找到如下两行文本：

```text
#font.family         : sans-serif
#font.sans-serif     : Bitstream Vera Sans, Lucida Grande, Verdana, Geneva, Lucid, Arial, Helvetica, Avant Garde, sans-serif
```

将这两行的`#`删掉，并在font.sans-serif中添加中文字体（如SimHei、Microsoft YaHei等）置于首位。

就像这样：

```text
font.family         : sans-serif
font.sans-serif     : Microsoft YaHei,SimHei,DejaVu Sans, Bitstream Vera Sans, Computer Modern Sans Serif, Lucida Grande, Verdana, Geneva, Lucid, Arial, Helvetica, Avant Garde, sans-serif
```

保存并退出即可。

此方法是永久修改，一旦修改，之后绘图时默认都使用中文字体显示图中字符。
