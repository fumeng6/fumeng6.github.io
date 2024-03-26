---
title: python中matplotlib的常用布局方式
date: 2024-3-26 15:00:00 +0800
categories: [编程相关,Python相关]
tags: [python绘图, matplotlib]
render_with_liquid: false
---

Matplotlib是Python中最流行的绘图库之一，它提供了多种工具来安排子图（subplots）。在这篇指南中，我们将探索不同的子图布局工具，包括最新的`subplot_mosaic`方法。每种工具都有其用途和优势，适用于不同的绘图需求。

## plt.subplot

最基本的方法是`plt.subplot`，它可以快速创建单个子图。该方法通过行数、列数和子图索引的方式进行布局。

```python
import matplotlib.pyplot as plt

plt.subplot(2, 1, 1)  # 第一行的第一个子图
plt.plot([1, 2, 3], [1, 2, 3])

plt.subplot(2, 1, 2)  # 第二行的第一个子图
plt.plot([1, 2, 3], [3, 2, 1])

plt.show()
```

## plt.subplots

`plt.subplots` 是一个更高级的API，它一次性创建一个子图网格。这个方法返回一个Figure对象和一个子图数组，使得同时管理多个子图变得简单。

```python
fig, axs = plt.subplots(2, 2)  # 2x2的子图网格

axs[0, 0].plot([1, 2, 3], [1, 2, 3])
axs[0, 1].plot([1, 2, 3], [3, 2, 1])
axs[1, 0].plot([1, 2, 3], [2, 3, 1])
axs[1, 1].plot([1, 2, 3], [3, 1, 2])

plt.show()
```

## plt.subplot2grid

`subplot2grid` 允许更多自由度。你可以指定网格的大小，子图在网格中的位置，以及它跨越的行数和列数。

```python
ax1 = plt.subplot2grid((3, 3), (0, 0), colspan=2)
ax2 = plt.subplot2grid((3, 3), (1, 0), rowspan=2)
ax3 = plt.subplot2grid((3, 3), (0, 2), rowspan=3)

ax1.plot([1, 2, 3], [1, 2, 3])
ax2.plot([1, 2, 3], [3, 2, 1])
ax3.plot([1, 2, 3], [2, 3, 1])

plt.tight_layout()
plt.show()
```

## GridSpec

`GridSpec` 是一种更为高级的网格布局系统。它提供了比`subplot2grid`更精细的控制能力，特别适用于创建复杂的布局。

```python
import matplotlib.gridspec as gridspec

gs = gridspec.GridSpec(2, 3)

ax1 = plt.subplot(gs[0, :2])
ax2 = plt.subplot(gs[1, 0])
ax3 = plt.subplot(gs[1, 1:])
ax4 = plt.subplot(gs[0, 2])

ax1.plot([1, 2, 3], [1, 2, 3])
ax2.plot([1, 2, 3], [3, 2, 1])
ax3.plot([1, 2, 3], [2, 3, 1])
ax4.plot([1, 2, 3], [1, 3, 2])

plt.tight_layout()
plt.show()
```

## add_axes

如果你需要完全自定义子图的尺寸和位置，`add_axes` 是最适合的。这个方法需要一个由[left, bottom, width, height]组成的列表。

```python
fig = plt.figure()
ax1 = fig.add_axes([0.1, 0.1, 0.8, 0.8])  # 主轴
ax2 = fig.add_axes([0.2, 0.5, 0.4, 0.3])  # 内嵌轴

ax1.plot([1, 2, 3], [1, 2, 3])
ax2.plot([1, 2, 3], [3, 2, 1])

plt.show()
```

`add_axes`非常灵活，它允许你在图形中的几乎任何位置添加子图，而且你可以精确控制其大小和位置。

## subplot_mosaic

`subplot_mosaic` 是Matplotlib 3.4版本新增的功能，它可以通过ASCII art风格的布局模式来创建子图。

```python
axs = plt.figure(constrained_layout=True).subplot_mosaic(
    """
    AAB
    ACC
    """
)

axs['A'].plot([1, 2, 3], [1, 2, 3])
axs['B'].plot([1, 2, 3], [3, 2, 1])
axs['C'].plot([1, 2, 3], [2, 3, 1])

plt.show()
```

在这个例子中，'A'代表了占据左侧两行的大子图，'B'和'C'分别代表了右上角和右下角的子图。

## 总结

在长期使用中，选择最适合你工作流程的布局工具非常重要。如果你需要创建常规的、结构化的网格布局，`plt.subplots()`是一个不错的选择，因为它简单易用且功能强大。如果你需要更多的布局灵活性，`GridSpec`可能是更好的选择。`subplot_mosaic`提供了一个非常直观且易读的方式来设计复杂布局，特别是在视觉上映射布局时。

记住，无论你选择哪种布局工具，重要的是它能够帮助你有效地表达你的数据故事。尝试不同的方法，并找到最适合你当前和未来项目的那一个。
