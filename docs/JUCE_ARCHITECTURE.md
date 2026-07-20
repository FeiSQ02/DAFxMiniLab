# JUCE 插件架构入门：音量与硬削波

> 用两个最简单的效果器，搭出一个方便增加、维护和更新效果器的工程结构。

---

## 1. 最终工程结构

```text
Source/
├── dsp/
│   ├── VolumeEffect.h
│   ├── VolumeEffect.cpp
│   ├── HardClipEffect.h
│   └── HardClipEffect.cpp
│
├── ui/
│   ├── VolumePanel.h
│   ├── VolumePanel.cpp
│   ├── HardClipPanel.h
│   └── HardClipPanel.cpp
│
├── PluginProcessor.h
├── PluginProcessor.cpp
├── PluginEditor.h
└── PluginEditor.cpp
```

每一层只做自己的事：

| 位置 | 职责 |
|---|---|
| `dsp/` | 音频算法，不负责界面 |
| `ui/` | 单个效果器的控件、参数绑定和内部布局 |
| `PluginProcessor` | 注册参数，按照顺序调用效果器 |
| `PluginEditor` | 把不同效果器面板排列到主窗口 |

最终两个主函数会很简单：

```text
PluginProcessor::processBlock()
    → 调用 VolumeEffect
    → 调用 HardClipEffect

PluginEditor::resized()
    → 排列 VolumePanel
    → 排列 HardClipPanel
```

---

## 2. 音频和参数怎样流动

```text
用户转动 VolumePanel 的 Gain
              ↓
SliderAttachment 更新 APVTS 参数
              ↓
PluginProcessor 读取 volume_gain
              ↓
VolumeEffect 处理音频
              ↓
HardClipEffect 继续处理
              ↓
输出到 DAW
```

这里有三条规则：

1. UI 面板不直接处理音频。
2. DSP 类不直接访问 UI，也不需要知道 APVTS。
3. Processor 是中间的管理者，负责把参数交给 DSP 类。

---

## 3. 第一步：建立 dsp 和 ui 目录

在 `plugins/DAFxMiniLab/Source/` 下创建：

```text
dsp/
ui/
```

然后通过 Projucer 把后面创建的 `.h` 和 `.cpp` 文件加入工程：

1. 在 Projucer 中打开 `DAFxMiniLab.jucer`。
2. 在 Source 分组下新建 `dsp` 和 `ui` 分组。
3. 右键分组，选择 **Add Existing Files...**。
4. 把对应文件加入分组。
5. 保存 Projucer 工程，再打开 Visual Studio。

注意：只在磁盘上创建 `.cpp` 文件，但没有加入 Projucer 工程，编译器不会编译它。

---

## 4. 第二步：实现 VolumeEffect

### 4.1 声明类

创建 `Source/dsp/VolumeEffect.h`：

```cpp
#pragma once

#include <JuceHeader.h>

class VolumeEffect
{
public:
    void prepare(double sampleRate);
    void reset();

    void setGainDb(float gainDb);
    void process(juce::AudioBuffer<float>& buffer);

private:
    juce::SmoothedValue<float> gainLinear { 1.0f };
};
```

头文件只告诉外部这个效果器能做什么：

- `prepare()`：播放前初始化。
- `reset()`：重置内部状态。
- `setGainDecibels()`：接收当前 Gain 参数。
- `process()`：处理一块音频。

### 4.2 实现类

创建 `Source/dsp/VolumeEffect.cpp`：

```cpp
#include "VolumeEffect.h"

void VolumeEffect::prepare(double sampleRate)
{
    gainLinear.reset(sampleRate, 0.02);
    gainLinear.setCurrentAndTargetValue(1.0f);
}

void VolumeEffect::reset()
{
    gainLinear.setCurrentAndTargetValue(gainLinear.getTargetValue());
}

void VolumeEffect::setGainDb(float gainDb)
{
    gainLinear.setTargetValue(
        juce::Decibels::decibelsToGain(gainDb));
}

void VolumeEffect::process(juce::AudioBuffer<float>& buffer)
{
    for (int sample = 0; sample < buffer.getNumSamples(); ++sample)
    {
        const float gain = gainLinear.getNextValue();

        for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
            buffer.setSample(channel,
                             sample,
                             buffer.getSample(channel, sample) * gain);
    }
}
```

`SmoothedValue` 让旋钮变化时音量平滑过渡，避免突然跳变产生咔哒声。

Volume 的核心仍然只有一句：

```text
输出 = 输入 × 音量倍数
```

---

## 5. 第三步：实现 HardClipEffect

### 5.1 声明类

创建 `Source/dsp/HardClipEffect.h`：

```cpp
#pragma once

#include <JuceHeader.h>

class HardClipEffect
{
public:
    void prepare(double sampleRate);
    void reset();

    void setThresholdDecibels(float thresholdDb);
    void process(juce::AudioBuffer<float>& buffer);

private:
    juce::SmoothedValue<float> thresholdLinear { 1.0f };
};
```

### 5.2 实现类

创建 `Source/dsp/HardClipEffect.cpp`：

```cpp
#include "HardClipEffect.h"

void HardClipEffect::prepare(double sampleRate)
{
    thresholdLinear.reset(sampleRate, 0.02);
    thresholdLinear.setCurrentAndTargetValue(1.0f);
}

void HardClipEffect::reset()
{
    thresholdLinear.setCurrentAndTargetValue(
        thresholdLinear.getTargetValue());
}

void HardClipEffect::setThresholdDecibels(float thresholdDb)
{
    thresholdLinear.setTargetValue(
        juce::Decibels::decibelsToGain(thresholdDb));
}

void HardClipEffect::process(juce::AudioBuffer<float>& buffer)
{
    for (int sample = 0; sample < buffer.getNumSamples(); ++sample)
    {
        const float threshold = thresholdLinear.getNextValue();

        for (int channel = 0; channel < buffer.getNumChannels(); ++channel)
        {
            const float input = buffer.getSample(channel, sample);
            const float output = juce::jlimit(-threshold,
                                               threshold,
                                               input);

            buffer.setSample(channel, sample, output);
        }
    }
}
```

硬削波的规则是：

```text
输入超过正阈值 → 截成正阈值
输入低于负阈值 → 截成负阈值
没有超过阈值   → 保持原样
```

例如阈值为 `0.5`：

```text
输入：-0.8  -0.3   0.2   0.7
输出：-0.5  -0.3   0.2   0.5
```

---

## 6. 第四步：在 Processor 中管理两个效果器

### 6.1 修改 PluginProcessor.h

包含两个 DSP 类：

```cpp
#include "dsp/VolumeEffect.h"
#include "dsp/HardClipEffect.h"
```

在类中加入参数系统和效果器对象：

```cpp
public:
    juce::AudioProcessorValueTreeState apvts;

private:
    static juce::AudioProcessorValueTreeState::ParameterLayout
        createParameterLayout();

    VolumeEffect volumeEffect;
    HardClipEffect hardClipEffect;
```

Processor 只持有对象，不需要知道效果器内部怎样计算。

### 6.2 注册参数

第一版只使用四个参数：

| 效果器 | 参数 ID | 默认值 |
|---|---|---|
| Volume | `volume_enabled` | 开 |
| Volume | `volume_gain` | 0 dB |
| Hard Clip | `hardclip_enabled` | 关 |
| Hard Clip | `hardclip_threshold` | -6 dB |

在 `PluginProcessor.cpp` 中实现：

```cpp
juce::AudioProcessorValueTreeState::ParameterLayout
DAFxMiniLabAudioProcessor::createParameterLayout()
{
    juce::AudioProcessorValueTreeState::ParameterLayout layout;

    layout.add(std::make_unique<juce::AudioParameterBool>(
        juce::ParameterID { "volume_enabled", 1 },
        "Volume Enabled",
        true));

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        juce::ParameterID { "volume_gain", 1 },
        "Volume Gain",
        juce::NormalisableRange<float> { -24.0f, 12.0f, 0.1f },
        0.0f));

    layout.add(std::make_unique<juce::AudioParameterBool>(
        juce::ParameterID { "hardclip_enabled", 1 },
        "Hard Clip Enabled",
        false));

    layout.add(std::make_unique<juce::AudioParameterFloat>(
        juce::ParameterID { "hardclip_threshold", 1 },
        "Hard Clip Threshold",
        juce::NormalisableRange<float> { -24.0f, 0.0f, 0.1f },
        -6.0f));

    return layout;
}
```

在 Processor 构造函数的初始化列表中初始化 APVTS：

```cpp
apvts(*this, nullptr, "Parameters", createParameterLayout())
```

### 6.3 准备效果器

在 `prepareToPlay()` 中：

```cpp
void DAFxMiniLabAudioProcessor::prepareToPlay(
    double sampleRate,
    int samplesPerBlock)
{
    juce::ignoreUnused(samplesPerBlock);

    volumeEffect.prepare(sampleRate);
    hardClipEffect.prepare(sampleRate);
}
```

在 `releaseResources()` 中重置：

```cpp
void DAFxMiniLabAudioProcessor::releaseResources()
{
    volumeEffect.reset();
    hardClipEffect.reset();
}
```

### 6.4 在 processBlock 中调用

```cpp
void DAFxMiniLabAudioProcessor::processBlock(
    juce::AudioBuffer<float>& buffer,
    juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    juce::ignoreUnused(midiMessages);

    const bool volumeEnabled =
        apvts.getRawParameterValue("volume_enabled")->load() > 0.5f;

    const float gainDb =
        apvts.getRawParameterValue("volume_gain")->load();

    volumeEffect.setGainDecibels(gainDb);

    if (volumeEnabled)
        volumeEffect.process(buffer);

    const bool hardClipEnabled =
        apvts.getRawParameterValue("hardclip_enabled")->load() > 0.5f;

    const float thresholdDb =
        apvts.getRawParameterValue("hardclip_threshold")->load();

    hardClipEffect.setThresholdDecibels(thresholdDb);

    if (hardClipEnabled)
        hardClipEffect.process(buffer);
}
```

现在 `processBlock()` 不包含具体算法，只做三件事：

```text
读取参数 → 设置效果器 → 调用效果器
```

处理顺序是：

```text
VolumeEffect → HardClipEffect
```

因此提高 Volume Gain 会更容易超过削波阈值，失真会更明显。

---

## 7. 第五步：建立独立的 VolumePanel

### 7.1 声明面板

创建 `Source/ui/VolumePanel.h`：

```cpp
#pragma once

#include <JuceHeader.h>

class VolumePanel : public juce::Component
{
public:
    explicit VolumePanel(juce::AudioProcessorValueTreeState& apvts);

    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    using ButtonAttachment =
        juce::AudioProcessorValueTreeState::ButtonAttachment;
    using SliderAttachment =
        juce::AudioProcessorValueTreeState::SliderAttachment;

    juce::ToggleButton enabledButton { "Enabled" };
    juce::Slider gainSlider;
    juce::Label gainLabel;

    ButtonAttachment enabledAttachment;
    SliderAttachment gainAttachment;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(VolumePanel)
};
```

这个类自己管理 Volume 的全部 UI：

- Enabled 开关。
- Gain 标签和旋钮。
- 两个 Attachment。
- 控件在面板内部的位置。

### 7.2 实现面板

创建 `Source/ui/VolumePanel.cpp`：

```cpp
#include "VolumePanel.h"

VolumePanel::VolumePanel(juce::AudioProcessorValueTreeState& apvts)
    : enabledAttachment(apvts, "volume_enabled", enabledButton),
      gainAttachment(apvts, "volume_gain", gainSlider)
{
    addAndMakeVisible(enabledButton);
    addAndMakeVisible(gainSlider);
    addAndMakeVisible(gainLabel);

    gainSlider.setSliderStyle(
        juce::Slider::RotaryHorizontalVerticalDrag);
    gainSlider.setTextBoxStyle(
        juce::Slider::TextBoxBelow, false, 80, 22);
    gainSlider.setTextValueSuffix(" dB");

    gainLabel.setText("Gain", juce::dontSendNotification);
    gainLabel.setJustificationType(juce::Justification::centred);
}

void VolumePanel::paint(juce::Graphics& g)
{
    g.setColour(juce::Colours::grey);
    g.drawRoundedRectangle(getLocalBounds().toFloat().reduced(1.0f),
                           8.0f,
                           1.0f);

    g.setColour(juce::Colours::white);
    g.drawText("VOLUME",
               12, 8, getWidth() - 24, 24,
               juce::Justification::centred);
}

void VolumePanel::resized()
{
    auto area = getLocalBounds().reduced(20);
    area.removeFromTop(28);

    enabledButton.setBounds(area.removeFromTop(28));
    gainLabel.setBounds(area.removeFromTop(24));
    gainSlider.setBounds(area);
}
```

---

## 8. 第六步：建立独立的 HardClipPanel

Hard Clip 面板和 Volume 面板结构相同，只替换控件和参数 ID。

### 8.1 声明面板

创建 `Source/ui/HardClipPanel.h`：

```cpp
#pragma once

#include <JuceHeader.h>

class HardClipPanel : public juce::Component
{
public:
    explicit HardClipPanel(juce::AudioProcessorValueTreeState& apvts);

    void paint(juce::Graphics& g) override;
    void resized() override;

private:
    using ButtonAttachment =
        juce::AudioProcessorValueTreeState::ButtonAttachment;
    using SliderAttachment =
        juce::AudioProcessorValueTreeState::SliderAttachment;

    juce::ToggleButton enabledButton { "Enabled" };
    juce::Slider thresholdSlider;
    juce::Label thresholdLabel;

    ButtonAttachment enabledAttachment;
    SliderAttachment thresholdAttachment;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(HardClipPanel)
};
```

### 8.2 实现面板

创建 `Source/ui/HardClipPanel.cpp`：

```cpp
#include "HardClipPanel.h"

HardClipPanel::HardClipPanel(
    juce::AudioProcessorValueTreeState& apvts)
    : enabledAttachment(apvts, "hardclip_enabled", enabledButton),
      thresholdAttachment(apvts,
                          "hardclip_threshold",
                          thresholdSlider)
{
    addAndMakeVisible(enabledButton);
    addAndMakeVisible(thresholdSlider);
    addAndMakeVisible(thresholdLabel);

    thresholdSlider.setSliderStyle(
        juce::Slider::RotaryHorizontalVerticalDrag);
    thresholdSlider.setTextBoxStyle(
        juce::Slider::TextBoxBelow, false, 80, 22);
    thresholdSlider.setTextValueSuffix(" dB");

    thresholdLabel.setText("Threshold", juce::dontSendNotification);
    thresholdLabel.setJustificationType(juce::Justification::centred);
}

void HardClipPanel::paint(juce::Graphics& g)
{
    g.setColour(juce::Colours::grey);
    g.drawRoundedRectangle(getLocalBounds().toFloat().reduced(1.0f),
                           8.0f,
                           1.0f);

    g.setColour(juce::Colours::white);
    g.drawText("HARD CLIP",
               12, 8, getWidth() - 24, 24,
               juce::Justification::centred);
}

void HardClipPanel::resized()
{
    auto area = getLocalBounds().reduced(20);
    area.removeFromTop(28);

    enabledButton.setBounds(area.removeFromTop(28));
    thresholdLabel.setBounds(area.removeFromTop(24));
    thresholdSlider.setBounds(area);
}
```

以后修改 Hard Clip 的界面，只需要打开 `HardClipPanel.h/.cpp`，不会影响 Volume 面板和主 Editor。

---

## 9. 第七步：让 PluginEditor 只负责排列面板

### 9.1 修改 PluginEditor.h

```cpp
#include "ui/VolumePanel.h"
#include "ui/HardClipPanel.h"
```

在 `private` 区域声明：

```cpp
DAFxMiniLabAudioProcessor& audioProcessor;

VolumePanel volumePanel;
HardClipPanel hardClipPanel;
```

### 9.2 修改 PluginEditor.cpp

构造函数把 APVTS 交给两个面板：

```cpp
DAFxMiniLabAudioProcessorEditor::DAFxMiniLabAudioProcessorEditor(
    DAFxMiniLabAudioProcessor& p)
    : AudioProcessorEditor(&p),
      audioProcessor(p),
      volumePanel(p.apvts),
      hardClipPanel(p.apvts)
{
    addAndMakeVisible(volumePanel);
    addAndMakeVisible(hardClipPanel);

    setSize(640, 320);
}
```

`paint()` 只画主窗口背景：

```cpp
void DAFxMiniLabAudioProcessorEditor::paint(juce::Graphics& g)
{
    g.fillAll(getLookAndFeel().findColour(
        juce::ResizableWindow::backgroundColourId));
}
```

`resized()` 只排列两个面板：

```cpp
void DAFxMiniLabAudioProcessorEditor::resized()
{
    auto area = getLocalBounds().reduced(16);
    auto left = area.removeFromLeft(area.getWidth() / 2);

    volumePanel.setBounds(left.reduced(8));
    hardClipPanel.setBounds(area.reduced(8));
}
```

到这里，主 Editor 不再声明任何 Gain 或 Threshold 控件，也不用知道控件在面板内部怎样排列。

---

## 10. 第八步：保存和恢复参数

在 `PluginProcessor.cpp` 中：

```cpp
void DAFxMiniLabAudioProcessor::getStateInformation(
    juce::MemoryBlock& destData)
{
    auto state = apvts.copyState();
    auto xml = state.createXml();
    copyXmlToBinary(*xml, destData);
}

void DAFxMiniLabAudioProcessor::setStateInformation(
    const void* data,
    int sizeInBytes)
{
    auto xml = getXmlFromBinary(data, sizeInBytes);

    if (xml != nullptr && xml->hasTagName(apvts.state.getType()))
        apvts.replaceState(juce::ValueTree::fromXml(*xml));
}
```

这样 DAW 保存工程时，四个参数都会一起保存。

---

## 11. 完成后的职责关系

```text
PluginEditor
├── VolumePanel
│   ├── Volume 控件
│   └── Volume 参数绑定
│
└── HardClipPanel
    ├── Hard Clip 控件
    └── Hard Clip 参数绑定

PluginProcessor
├── APVTS 参数
├── VolumeEffect
└── HardClipEffect
```

主文件只负责组织：

```cpp
// PluginProcessor.cpp
volumeEffect.process(buffer);
hardClipEffect.process(buffer);
```

```cpp
// PluginEditor.cpp
volumePanel.setBounds(...);
hardClipPanel.setBounds(...);
```

具体算法和具体 UI 都留在各自文件中。

---

## 12. 以后怎样增加第三个效果器

假设以后增加 Tremolo：

```text
dsp/TremoloEffect.h
dsp/TremoloEffect.cpp
ui/TremoloPanel.h
ui/TremoloPanel.cpp
```

然后只需要：

1. 在 APVTS 中注册 Tremolo 参数。
2. 在 Processor 中增加 `TremoloEffect` 对象并调用。
3. 在 Editor 中增加 `TremoloPanel` 对象并排列。

原来的 Volume 和 Hard Clip 文件都不需要改。

这就是把 DSP 和 UI 都按效果器分类的主要价值。

---

## 13. 推荐实际操作顺序

每完成一步就编译一次：

1. 创建 `dsp/VolumeEffect.h/.cpp`。
2. 把文件加入 Projucer，编译。
3. 在 Processor 中注册 Volume 参数并调用，试听。
4. 创建 `ui/VolumePanel.h/.cpp`，绑定参数，试听。
5. 创建 `dsp/HardClipEffect.h/.cpp`，编译。
6. 在 Processor 中注册 Hard Clip 参数并调用，试听。
7. 创建 `ui/HardClipPanel.h/.cpp`，绑定参数，试听。
8. 把两个面板放入 PluginEditor。
9. 实现参数保存和恢复。

出现错误时，只检查刚刚增加的那一步，不要同时修改多个层。
