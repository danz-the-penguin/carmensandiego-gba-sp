# Where in the World is Carmen Sandiego? — Game Boy Advance SP Edition

[![Godot Engine](https://img.shields.io/badge/Godot-4.7-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Web-f59e0b)](#running-the-game)
[![Aspect Ratio](https://img.shields.io/badge/Screen-3%3A2%20GBA%20SP-38bdf8)](#retro-visual-architecture)
[![Audio](https://img.shields.io/badge/Audio-8--bit%20PSG%20Synthesizer-10b981)](#audio-synthesis)

A faithful retro detective adventure inspired by the 1985 classic *"Where in the World is Carmen Sandiego?"*, crafted in the authentic hardware aesthetic of the **Nintendo Game Boy Advance SP (AGS-101 / AGS-001)**. Built with **Godot 4** and featuring a companion **HTML5/Web Audio** clamshell prototype.

---

## 🕵️ Features & Detective Mechanics

* **16 Global Capitals & Closed Route Network:** Travel from London, Paris, and Cairo to Tokyo, Reykjavik, Kathmandu, and Sydney across a fully connected flight graph.
* **8 V.I.L.E. Criminals & Carmen Sandiego:** Track down Len Bulk, Lady Agatha, Nick Brunch, Fast Eddie, and Carmen herself.
* **12 World Treasures:** Recover stolen artifacts including the Crown Jewels, the Mona Lisa, the Rosetta Stone, and Tutankhamun's Gold Mask.
* **Interpol Crime Computer:** Input physical traits (Gender, Hair, Vehicle, Hobby, Feature) to compute and issue legally binding arrest warrants before closing in on the hideout.
* **GBA SP Clamshell UI:** True 3:2 aspect ratio, razor-sharp 8px bitmap typography (`antialiasing = 0`), and dynamic city sky palettes.
* **Career Persistence:** Profile progress automatically saves cases solved and detective promotions from **Rookie** to **Ace Detective**.

---

## 🎮 GBA SP Controls

| GBA SP Button | Keyboard Equivalent | Game Action |
| :--- | :--- | :--- |
| **D-Pad** | <kbd>↑</kbd> <kbd>↓</kbd> <kbd>←</kbd> <kbd>→</kbd> / Arrow Keys | Navigate menus & 2×2 hub options |
| **[A] Button** | <kbd>Z</kbd> / <kbd>Space</kbd> / Left Click | Confirm, question witnesses, fast-forward text |
| **[B] Button** | <kbd>X</kbd> / <kbd>Escape</kbd> | Cancel, close submenus, go back |
| **[L] Shoulder** | <kbd>Q</kbd> | Open Case Notes / Clue Dossier |
| **[R] Shoulder** | <kbd>E</kbd> | Open Interpol Crime Computer |
| **[START]** | <kbd>Enter</kbd> / <kbd>Space</kbd> / Click | Start new case from Title Screen |
| **Light Button** | <kbd>B</kbd> | Cycle AGS-101 Bright / Normal / Frontlit |

*Full mouse clicking is supported across all menus, buttons, and dialogue boxes.*

---

## 🖥️ Retro Visual & Audio Architecture

1. **Pixel-Perfect 2× Viewport (480 × 320):**
   * Configured in Godot 4 for a strict 3:2 aspect ratio integer scale with window scaling at 960 × 640.
   * `PressStart2P` pixel font with `antialiasing = 0`, `hinting = 0`, and `subpixel_positioning = 0` guarantees razor-sharp text on modern displays without blur.
   * `NSHighResolutionCapable = true` enabled in macOS app bundle for native Retina display backing.

2. **Dual-Channel 8-Bit Audio Synth:**
   * Pre-cached procedural square, triangle, and noise waveforms in RAM for zero latency.
   * Independent audio channels for UI effects and dialogue typewriter blips prevent audio cutoffs.

---

## 🚀 Running the Game

### 1. Standalone macOS App (.DMG)
Download the standalone signed DMG from [GitHub Releases](https://github.com/danz-the-penguin/carmensandiego-gba-sp/releases):
1. Open `CarmenSandiego_GBA_SP.dmg`.
2. Drag **Carmen Sandiego** to your **Applications** folder.
3. Launch and play!

### 2. Run via Godot 4 Engine
```bash
godot --path godot
```

### 3. Run Web Prototype
Open `index.html` in any modern web browser or start a local server:
```bash
npx serve .
```

---

## 📂 Repository Structure

```
├── godot/                     # Godot 4 Engine Source Project
│   ├── assets/                # Pixel fonts (PressStart2P), retro themes & styleboxes
│   ├── scenes/                # Godot scenes (main, title_screen, city_hub)
│   ├── scripts/               # GDScript logic & autoload singletons (Database, GameManager, SoundManager)
│   ├── shaders/               # GBA LCD subpixel & backlight shaders
│   ├── export_presets.cfg     # Preset for 1-click macOS DMG & app packaging
│   └── project.godot          # Project settings & viewport configuration
├── index.html                 # GBA SP Clamshell Web Audio/Canvas prototype
├── js/                        # Web engine, data, audio synthesis, and pixel art renderer
└── .gitignore                 # Excludes heavy binaries (>100MB) and editor cache
```

---

## 📜 License & Credits

* Inspired by Brøderbund Software's classic 1985 detective adventure.
* Built for retro gaming enthusiasts and Game Boy Advance SP nostalgia.
