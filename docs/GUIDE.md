# DAFxMiniLab 使用指南

> 从克隆仓库到运行 MATLAB 原型、构建 VST3 插件，一站式上手指南。

---

## 目录

1. [环境要求](#1-环境要求)
2. [克隆仓库](#2-克隆仓库)
3. [项目结构](#3-项目结构)
4. [运行 MATLAB 原型](#4-运行-matlab-原型)
5. [构建 VST3 插件](#5-构建-vst3-插件)
6. [在 DAW 中加载插件](#6-在-daw-中加载插件)
7. [开发工作流](#7-开发工作流)
8. [当前实现状态](#8-当前实现状态)
9. [常见问题排查](#9-常见问题排查)

---

## 1. 环境要求

### MATLAB 原型

- MATLAB（建议 R2019b 以上，没有的话 GNU Octave 也能凑合跑大部分脚本）
- 推荐安装 **Signal Processing Toolbox**（`pwelch`、`butter` 等函数会用到）

### VST3 插件构建

- [JUCE](https://juce.com/) 框架（含 Projucer 工程管理工具）
- Visual Studio（Windows）或 Xcode（macOS）

不需要特定版本，能编译 C++17 就行。

> **Visual Studio 安装提示：** 安装时只需勾选 **「使用 C++ 的桌面开发」** 这一个工作负载即可，MSVC 编译器、Windows SDK 等都会自动带上，其他组件一概不需要。

### 测试插件

- 任意支持 VST3 的 DAW（Reaper、Ableton Live、FL Studio、Cubase 等）
- 或者 JUCE 自带的 **AudioPluginHost**（无需完整 DAW，调试更方便）

---

## 2. 克隆仓库

```bash
git clone https://github.com/yourusername/DAFxMiniLab.git
cd DAFxMiniLab
```

---

## 3. 项目结构

```
DAFxMiniLab/
├── matlab/                     # 第一步：算法原型与分析
│   ├── eq/                     #   EQ 与滤波器
│   ├── dynamics/               #   动态处理
│   ├── modulation/             #   调制效果（✅Tremolo ✅RingMod）
│   ├── distortion/             #   失真（✅soft_clip）
│   ├── spatial/                #   空间音频
│   ├── psychoacoustics/        #   心理声学
│   ├── others/                 #   ✅CrossFade
│   └── utils/                  #   工具函数（✅InputGainSet ✅wavCut）
├── plugins/                    # 第二步：JUCE/C++ VST3 插件
│   └── DAFxMiniLab/
│       ├── DAFxMiniLab.jucer   # Projucer 工程文件
│       ├── Source/             # PluginProcessor + Editor
│       └── JuceLibraryCode/    # JUCE 库桥接（Projucer 自动生成，不用管）
├── data/                       # 测试音频
│   ├── in.wav
│   └── gtrDI.wav
└── docs/                       # 文档
```

**学习路径：** 先跑 `matlab/` 理解算法，再看 `plugins/Source/` 了解 C++ 实时实现。

---

## 4. 运行 MATLAB 原型



---

## 5. 构建 VST3 插件

### 5.1 安装 JUCE

1. 从 [juce.com](https://juce.com/) 下载 JUCE
2. 解压到固定位置（如 `C:\JUCE`）

### 5.2 配置 Projucer

1. 打开 Projucer
2. **File → Global Paths...**，设置 JUCE Modules 路径为 `C:\JUCE\modules`
3. 保存

### 5.3 打开工程并修正模块路径

1. 用 Projucer 打开 `plugins/DAFxMiniLab/DAFxMiniLab.jucer`
2. 当前 `.jucer` 里模块路径硬编码为 `C:/JUCE/modules`。如果你的路径不同，选左侧 exporter，在 **Module paths** 里更新每个模块路径
3. **Ctrl+S 保存**

### 5.4 导出到 IDE 并构建

1. Projucer 中点击 **"Save and Open in IDE"**，自动打开 Visual Studio
2. 选择 **Release** 配置，x64 平台
3. **生成 → 生成解决方案**

### 5.5 安装 VST3 到系统目录

构建完成后，需要把生成的 `.vst3` 文件夹复制到系统 VST3 目录，DAW 才能识别：

```powershell
# 构建产物在 Builds 目录下，例如：
# Builds\VisualStudio2026\x64\Release\VST3\DAFxMiniLab.vst3\

# 复制到系统 VST3 目录：
Copy-Item -Recurse -Force "Builds\VisualStudio2026\x64\Release\VST3\DAFxMiniLab.vst3" `
    "C:\Program Files\Common Files\VST3\"
```

> macOS 用户复制到 `~/Library/Audio/Plug-Ins/VST3/`。

> **注意：** 复制的是整个 `.vst3` **文件夹**（它是一个 bundle），不是单个文件。

### 5.6 当前插件状态

插件目前是 JUCE 模板骨架——能成功构建并加载，但：
- `processBlock()` 里还没有 DSP 算法（音频直接旁通）
- GUI 只显示 "Hello World!"

框架已搭好，就等你往 `processBlock()` 里填算法了。

---

## 6. 在 DAW 中加载插件

**方式 A — AudioPluginHost（推荐调试用）：**

从 Projucer 菜单启动 AudioPluginHost → Options → Edit the List of Available Plugins → 扫描 VST3 目录 → 拖入 DAFxMiniLab 即可测试。

**方式 B — 完整 DAW：**

重新扫描插件 → 在音轨 FX 槽中找到 "DAFxMiniLab" → 加载。

---

## 7. 开发工作流

```
MATLAB 原型（理解算法）
    ↓
调参，观察波形/频谱变化
    ↓
在 PluginProcessor.cpp 的 processBlock() 中用 C++ 实现
    ↓
构建插件 → DAW 实时试听 → 与 MATLAB 输出对比验证
```

### 快速上手

打开 `plugins/DAFxMiniLab/Source/PluginProcessor.cpp`，找到 `processBlock()`，把注释 `// ..do something to the data...` 替换成你的 DSP 代码：

```cpp
for (int channel = 0; channel < totalNumInputChannels; ++channel)
{
    auto* channelData = buffer.getWritePointer(channel);
    // 举个最简单的例子 —— tanh 软削波：
    for (int sample = 0; sample < buffer.getNumSamples(); ++sample)
        channelData[sample] = std::tanh(channelData[sample] * drive);
}
```

---



## 9. 常见问题排查

**Q: MATLAB 报"未定义函数或变量"**

忘记 `addpath(genpath('matlab'))` 了。

**Q: `audioread` 找不到音频文件**

脚本假设从 `matlab/` 子目录运行（相对路径 `../data/`）。`cd` 到仓库根目录再跑。

**Q: `pwelch` / `butter` 报错**

需要 Signal Processing Toolbox。`ver signal` 检查是否安装。

**Q: Projucer 打开 .jucer 后模块报红**

Global Paths 没设对，或者 exporter 里的模块路径还是旧的。逐个更新后保存即可。

**Q: VS 找不到 `JuceHeader.h`**

在 Projucer 里重新保存工程，会重新生成 `JuceLibraryCode/` 下所有文件。

**Q: DAW 扫描不到插件**

检查 `.vst3` 文件夹是否已复制到 `C:\Program Files\Common Files\VST3\`，然后手动触发 DAW 重新扫描。

**Q: 加载插件后没声音变化**

正常。`processBlock()` 还没有 DSP 代码，音频直接旁通。

---

## 更多资源

- [JUCE 官方教程](https://juce.com/learn/tutorials/)
- [JUCE Forum](https://forum.juce.com/)
- [DAFx 学术资源](http://www.dafx.de/)

---

*有问题欢迎提 Issue。*
