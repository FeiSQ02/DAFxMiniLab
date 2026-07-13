# DAFxMiniLab 

> A hands-on mini-laboratory for digital audio effects – from MATLAB theory to real-time VST3 plugins.

[English](README.md) | [中文](README.zh-CN.md)

---

**DAFxMiniLab** is an open-source learning project that guides you through the full journey of audio DSP development.  
You'll start by prototyping classic and modern audio effects in MATLAB, analysing their behaviour with plots and metrics,  
and then translate them into a real-time C++ VST3 plugin system using JUCE.

Perfect for students, self-learners, and developers who want to understand *what happens inside the box* when you twist a knob.

---

##  What's inside

-  **EQ & Filters** – parametric, shelving, graphic EQ design
-  **Dynamics** – compressor, expander, noise gate with timing analysis
-  **Modulation** – chorus, flanger, phaser
-  **Distortion** – tube overdrive, soft/hard clipping, waveshaping
-  **Spatial Audio** – HRTF-based binaural rendering with smooth interpolation
-  **Psychoacoustics** – virtual bass enhancement using harmonic synthesis
-  **Modular DSP chain** in a real-time audio plugin (VST3)

---

##  Project Structure

```
DAFxMiniLab/
├── matlab/                     # Step 1: Algorithm prototyping & analysis
│   ├── eq/
│   ├── dynamics/
│   ├── modulation/
│   ├── distortion/
│   ├── spatial/
│   ├── psychoacoustics/
│   ├── others/                 # Miscellaneous effects (e.g. crossfade)
│   └── utils/                  # Common plotting & frequency response tools
├── plugins/                     # Step 2: Real-time JUCE/C++ VST3 plugin
│   ├── Source/                 # PluginProcessor, Editor, and DSP modules
│   └── DAFxMiniLab.jucer       # Projucer project file (to be added)
├── data/                       # Shared resources (e.g., HRTF datasets)
│   └── hrtf/
└── docs/                       # Learning guides and design notes
    └── images/
```


**Learning path:** Start with the `matlab/` folder to understand the theory and behaviour of each effect.  
Then explore `plugins/Source/` to see how the same algorithms are implemented in C++ for real-time usage.

---

##  Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/DAFxMiniLab.git
cd DAFxMiniLab
```

### 2. Run MATLAB prototypes
Open any .m file inside the matlab/ subfolders and run it.
Each script is self-contained and produces visualizations like frequency response, waveforms, or perceptual curves.

Requirements: MATLAB R2019b or later (Signal Processing Toolbox recommended for some scripts).

### 3. Build the VST3 plugin (after C++ phase is added)

1. Open `plugin/DAFxMiniLab.jucer` in Projucer (JUCE 7+).
2. Export the project to your IDE (Visual Studio / Xcode).
3. Build the plugin and load it into any DAW that supports VST3.

The plugin source code will be added progressively, matching each MATLAB effect.

##  Why this project exists

Most audio DSP tutorials stop at either theory or a simple offline script.
DAFxMiniLab bridges the gap by:

- Giving you runnable, visually explained prototypes (MATLAB)
- Showing how to turn them into a real-time plugin with JUCE/C++
- Keeping everything in one repository so you can compare theory ↔ implementation side‑by‑side
- Focusing on headphone & small‑speaker challenges like bass enhancement and spatial rendering

##  License

This project is licensed under the MIT License – see LICENSE for details.

##  Contributing

Contributions, improvements, and additional effect modules are very welcome!
Feel free to open an issue or submit a pull request.

DAFxMiniLab – learn digital audio effects from scratch, one knob at a time！