---
title: python简单GUI实现
date: 2023-05-26 13:02:58 +0800
categories: [编程相关,Python相关]
tag: [python,gui]
render_with_liquid: false
---

## 示例程序

下面的示例使用Tkinter创建了一个简单的GUI应用程序，具有左侧的导航栏和右侧的内容区域，通过点击导航栏中的按钮可以切换显示不同的页面。

下面是对程序的解释：

1. 导入必要的Tkinter模块和组件：

   ```python
   import tkinter as tk
   from tkinter import ttk
   from tkinter import filedialog
   ```

2. 创建`App`类，继承自`tk.Tk`：

   ```python
   class App(tk.Tk):
       def __init__(self):
           super().__init__()

           self.title("简单的GUI程序")
           self.geometry("600x400")

           self.create_widgets()
   ```

   在初始化方法`__init__()`中，设置窗口的标题和大小，并调用`create_widgets()`方法创建界面的组件。

3. 创建界面组件：

   ```python
   def create_widgets(self):
       self.sidebar = tk.Frame(self, background="#CCCCCC", width=200)
       self.sidebar.pack(side=tk.LEFT, fill=tk.Y)

       self.content = tk.Frame(self, background="#F0F0F0")
       self.content.pack(side=tk.RIGHT, fill=tk.BOTH, expand=True)

       self.pages = {}
       self.create_sidebar_buttons()
       self.create_pages()
   ```

   这里创建了两个框架，`self.sidebar`用于放置导航栏按钮，`self.content`用于放置页面内容。`self.pages`字典用于存储不同页面的框架对象。

4. 创建导航栏按钮：

   ```python
   def create_sidebar_buttons(self):
       button_names = ["页面1", "页面2", "页面3"]
       for name in button_names:
           button = tk.Button(
               self.sidebar, text=name, command=lambda n=name: self.show_page(n)
           )
           button.pack(fill=tk.X)
   ```

   使用循环创建了导航栏中的按钮，并为每个按钮绑定了对应的页面切换方法。

5. 创建页面框架和内容：

   ```python
   def create_pages(self):
       for i in range(1, 4):
           page_name = f"页面{i}"
           self.pages[page_name] = ttk.Frame(self.content)
           label = ttk.Label(
               self.pages[page_name], text=f"这是{page_name}", font=("Arial", 20)
           )
           label.pack(expand=True)

       self.show_page("页面1")
   ```

   使用循环创建了三个页面框架，每个页面框架中包含一个标签用于显示页面名称。默认显示第一个页面。

6. 实现页面切换功能：

   ```python
   def show_page(self, name):
       for page in self.pages.values():
           page.pack_forget()

       self.pages[name].pack(fill=tk.BOTH, expand=True)
   ```

   `show_page()`方法根据传入的页面名称，将所有页面框架隐藏，然后显示对应的页面框架。

7. 实现文件选择功能：

   ```python
   def select_file(self):
       file_path = filedialog.askopenfilename()
       self.file_label.config(text=file_path)
       self.file_path = file_path
   ```

   `select_file()`方法通过调用文件对话框选择文件，并将选择的文件路径显示在页面一上的标签中。

8. 创建`App`实例并启动程序：

   ```python
   if __name__ == "__main__":
       app = App()
       app.mainloop()
   ```

   创建了`App`类的实例，并调用`mainloop()`方法启动程序的事件循环，使窗口保持显示状态。

这个程序通过使用Tkinter的各种组件和布局管理器，实现了一个简单的GUI应用程序，并展示了页面切换和文件选择的功能。

希望这个解释对你有帮助。如果你还有其他问题，请随时提问。

## 打包为可执行文件

可以使用PyInstaller来打包你的Python程序。PyInstaller是另一个常用的打包工具，它可以将Python程序打包成独立的可执行文件，适用于不同的操作系统。

以下是使用PyInstaller打包程序的步骤：

1. 首先，确保你已经安装了PyInstaller。如果没有安装，可以使用pip命令进行安装：

    ```powershell
    pip install pyinstaller
    ```

2. 打开命令行终端，并进入你的程序所在的目录。

3. 在命令行中运行以下命令，将你的Python程序打包为可执行文件：

    ```powershell
    pyinstaller --onefile your_script.py
    ```

  请确保将`your_script.py`替换为你的实际脚本文件名。

4. 执行以上命令后，PyInstaller将会在当前目录下创建一个`dist`文件夹，其中包含了打包好的可执行文件和其他必要的文件。

请注意，PyInstaller会将Python解释器和你的程序代码一起打包，生成一个独立的可执行文件。因此，生成的可执行文件可能会比较大。

另外，如果你的程序依赖于其他第三方库，PyInstaller会尝试自动检测并将这些依赖项一同打包到可执行文件中。但有时候可能会出现某些依赖项无法正确打包的情况。在这种情况下，你可以通过使用`--hidden-import`参数手动添加缺失的依赖项。

例如，如果你的程序依赖于`numpy`库，但PyInstaller没有正确识别到它，你可以运行以下命令手动添加：

```powershell
pyinstaller --onefile --hidden-import=numpy your_script.py
```

这样PyInstaller会将`numpy`库打包到可执行文件中。

### 使用打包脚本

如下为我常用的pyinstaller打包脚本：

```python
import shutil
from pathlib import Path
from PyInstaller.__main__ import run

# 清理之前的打包输出文件
shutil.rmtree(Path("dist"), ignore_errors=True)
shutil.rmtree(Path("build"), ignore_errors=True)

# PyInstaller 打包参数
opts = [
    # 需打包的程序
    "myresearch.py",
    # 打包后的程序名
    "--name=myresearch",
    # 清理打包缓存
    "--clean",
    # 自动化打包，过程中无需进行选项确认
    "--noconfirm",
    # 打包成单个文件
    "--onefile",
    # 以窗口形式打包，成品无控制台窗口
    "--windowed",
    # 设置应用图标
    "--icon=res/地球.ico",
    # 导入外部资源文件
    "--add-data=res/*;res/",
]

# 打包应用程序
run(opts)
```

打包完成之后即可在`dist`文件夹下找到你的`.exe`文件了。
