# DAFxMiniLab 

> 数字音频效果微型实验室 – 从 MATLAB 理论到实时 VST3 插件。

[English](README.md) | [中文](README.zh-CN.md)

---

**DAFxMiniLab** 是一个开源学习项目，带你走完音频 DSP 开发的完整旅程。  
你将从 MATLAB 中的经典与现代音频效果原型开始，通过图表和指标分析其行为，  
然后用 JUCE 将它们转化为实时 C++ VST3 插件系统。

适合学生、自学者和想要理解旋钮背后*盒子里究竟发生了什么*的开发者。

---

##  包含内容

-  **EQ 与滤波器** – 参量、搁架、图示 EQ 设计
-  **动态处理** – 压缩器、扩展器、噪声门及时间响应分析
-  **调制效果** – 合唱、镶边、移相
-  **失真** – 电子管过载、软/硬削波、波形塑形
-  **空间音频** – 基于 HRTF 的双耳渲染与平滑插值
-  **心理声学** – 利用谐波合成增强虚拟低音
-  **模块化 DSP 链路** – 集成于实时音频插件中（VST3）

---

##  项目结构

```
DAFxMiniLab/
├── matlab/                     # 第一步：算法原型与分析
│   ├── eq/
│   ├── dynamics/
│   ├── modulation/
│   ├── distortion/
│   ├── spatial/
│   ├── psychoacoustics/
│   ├── others/                 # 其他效果（如交叉淡化）
│   └── utils/                  # 通用绘图与频率响应工具
├── plugins/                     # 第二步：实时 JUCE/C++ VST3 插件
│   ├── Source/                 # PluginProcessor、Editor 与 DSP 模块
│   └── DAFxMiniLab.jucer       # Projucer 工程文件（待添加）
├── data/                       # 共享资源（如 HRTF 数据集）
│   └── hrtf/
└── docs/                       # 学习指南与设计笔记
    └── images/
```


**学习路径：** 从 `matlab/` 文件夹开始，理解每种效果的理论与行为。  
然后探索 `plugins/Source/`，了解相同算法如何用 C++ 实现实时运行。

---

##  快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/yourusername/DAFxMiniLab.git
cd DAFxMiniLab
```

### 2. 运行 MATLAB 原型

打开 `matlab/` 子文件夹中的任意 `.m` 文件并运行。
每个脚本都是自包含的，会生成频率响应、波形或感知曲线等可视化结果。

**环境要求：** MATLAB R2019b 或更高版本（部分脚本建议安装 Signal Processing Toolbox）。

### 3. 构建 VST3 插件（C++ 阶段添加后）

1. 在 Projucer（JUCE 7+）中打开 `plugin/DAFxMiniLab.jucer`。
2. 将工程导出到你的 IDE（Visual Studio / Xcode）。
3. 构建插件并在任意支持 VST3 的 DAW 中加载。

插件源码将逐步添加，与每个 MATLAB 效果一一对应。

---

##  为什么有这个项目

大多数音频 DSP 教程要么停留在理论层面，要么止步于简单的离线脚本。
DAFxMiniLab 弥合了这一差距：

- 提供可运行、可视化解释的原型（MATLAB）
- 展示如何将算法转化为实时插件（JUCE/C++）
- 所有内容集中在一个仓库中，方便对照理论 ↔ 实现
- 聚焦耳机与小音箱场景下的挑战，如低音增强与空间渲染

---

##  许可证

本项目基于 MIT License 许可 – 详见 LICENSE 文件。

---

##  参与贡献

欢迎各种贡献、改进以及新增效果模块！
请随时提交 Issue 或 Pull Request。

---

DAFxMiniLab – 从零开始学习数字音频效果，一个旋钮一个脚印！ 
