# Where in the World is Carmen Sandiego? — Game Boy Advance SP Edition

[![Godot Engine](https://img.shields.io/badge/Godot-4.7-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Web-f59e0b)](#running-the-game)
[![Aspect Ratio](https://img.shields.io/badge/Screen-3%3A2%20GBA%20SP-38bdf8)](#retro-visual-architecture)
[![Audio](https://img.shields.io/badge/Audio-8--bit%20Chiptune%20BGM%20%2B%20SFX-10b981)](#audio-synthesis)
[![GitHub Release](https://img.shields.io/github/v/release/danz-the-penguin/carmensandiego-gba-sp?color=34d399)](https://github.com/danz-the-penguin/carmensandiego-gba-sp/releases)

A 2010s neo-retro detective adventure inspired by the 1985 classic *"Where in the World is Carmen Sandiego?"* and the character-driven charm of *Phoenix Wright: Ace Attorney*, *Papers, Please*, and *FTL*. Crafted in the authentic hardware aesthetic of the **Nintendo Game Boy Advance SP (AGS-101 / AGS-001)**. Built with **Godot 4** and featuring a companion **HTML5/Web Audio** clamshell prototype.

---

## 🕵️ Features & 2010s Neo-Retro Mechanics

* **Expressive Character Pixel-Art Portraits:** Confront witnesses and suspects face-to-face with 12 handcrafted procedural avatars (Carmen Sandiego, 7 V.I.L.E. operatives, ACME Chief, Bank Teller, Airline Pilot, and Museum Curator) rendered in crisp 1px nearest-neighbor scaling.
* **Catchy Looping 8-Bit Chiptune Detective Groove:** Seamless procedural D-minor arpeggio, bassline, and noise percussion BGM that keeps cases thrilling. Press <kbd>M</kbd> at any time to toggle music.
* **V.I.L.E. Trail Heat Tension Gauge:** Real-time visual feedback in the HUD:
  * `● HOT TRAIL` (emerald glow) confirms you're on the fugitive's trail.
  * `▲ COLD TRAIL` (amber alert) warns when you take an incorrect flight route.
  * `★ CORNERED!` (crimson alert) pulses when closing in on the final hideout!
* **Global Flight Transit Radar Cutscene:** Departing for international destinations triggers an in-transit radar flight animation with travel time deduction counter (`-4 HOURS`).
* **Zero Cut-off Smart Word Wrapping & BBCode Highlights:** Dynamic `RichTextLabel` with keyword highlighting (cyan destinations, gold suspect traits, coral arrest alerts) and automatic word-smart wrapping on all submenu buttons and clue cards.
* **16 Global Capitals & Closed Route Network:** Travel from London, Paris, and Cairo to Tokyo, Reykjavik, Kathmandu, and Sydney across a fully connected flight graph.
* **Interpol Crime Computer:** Input physical traits (Gender, Hair, Vehicle, Hobby, Feature) to compute and issue legally binding arrest warrants before closing in on the hideout.
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
| **Mute BGM** | <kbd>M</kbd> | Toggle 8-bit Detective BGM On/Off |

*Full mouse clicking is supported across all menus, buttons, and dialogue boxes.*

---

## 🖥️ Retro Visual & Audio Architecture

1. **Pixel-Perfect 2× Viewport (480 × 320):**
   * Configured in Godot 4 for a strict 3:2 aspect ratio integer scale with window scaling at 960 × 640.
   * `PressStart2P` pixel font with `antialiasing = 0`, `hinting = 0`, and `subpixel_positioning = 0` guarantees razor-sharp text on modern displays without blur.
   * `NSHighResolutionCapable = true` enabled in macOS app bundle for native Retina display backing.

2. **Dual-Channel 8-Bit Audio Synth & Groove BGM:**
   * Pre-cached procedural square, triangle, and noise waveforms in RAM for zero latency.
   * Independent audio channels for UI effects, typewriter voice blips, and looping chiptune BGM prevent sound dropouts.

---

## 🚀 Running the Game

### 1. Standalone macOS App (.DMG)
Download the standalone signed DMG from [GitHub Releases](https://github.com/danz-the-penguin/carmensandiego-gba-sp/releases):
1. Download `CarmenSandiego_GBA_SP.dmg`.
2. Open `CarmenSandiego_GBA_SP.dmg` and drag **Carmen Sandiego** to your **Applications** folder.
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
│   ├── scripts/               # GDScript logic & autoload singletons
│   │   ├── autoload/          # Database, GameManager, PortraitManager, SoundManager
│   │   ├── city_hub.gd        # Hub, rich dialog, trail heat & flight radar
│   │   ├── title_screen.gd    # Title screen & stats
│   │   └── main.gd            # Scene switcher
│   ├── shaders/               # GBA LCD subpixel & backlight shaders
│   ├── export_presets.cfg     # Preset for 1-click macOS DMG & app packaging
│   └── project.godot          # Project settings & viewport configuration
├── index.html                 # GBA SP Clamshell Web Audio/Canvas prototype
├── js/                        # Web engine, data, audio synthesis, and pixel art renderer
└── .gitignore                 # Excludes heavy binaries (>100MB) and editor cache
```

---

## 📜 License & Credits

* Inspired by Brøderbund Software's classic 1985 detective adventure and 2010s neo-retro indie classics.
* Built for retro gaming enthusiasts and Game Boy Advance SP nostalgia.
