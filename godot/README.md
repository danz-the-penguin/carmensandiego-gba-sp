# Where in the World is Carmen Sandiego? — GBA SP Edition (Godot 4)

A retro detective adventure built with **Godot 4 (2D)** faithfully recreating the Game Boy Advance SP (AGS-001 / AGS-101) experience.

---

## 🚀 How to Run in Godot 4

### Option 1: Install Godot 4 on Mac via Homebrew
In your terminal, run:
```bash
brew install --cask godot
```
Or download **Godot Engine 4.x** directly from [godotengine.org](https://godotengine.org/download).

### Option 2: Open the Project
1. Launch **Godot 4**.
2. Click **Import**.
3. Browse to and select the `godot/` folder (or select `godot/project.godot`).
4. Click **Import & Edit**.
5. Press **F5** (or click the Play ▶ button in the top right) to run the game!

---

## 🎮 Game Boy Advance SP Controls

| GBA SP Hardware | Keyboard Key | Gamepad (Xbox/PlayStation) | Action |
| :--- | :--- | :--- | :--- |
| **D-Pad** | <kbd>▲/▼/◀/▶</kbd> or <kbd>W/A/S/D</kbd> | D-Pad / Left Stick | Move cursor / navigate menus |
| **[A] Button** | <kbd>Z</kbd>, <kbd>Space</kbd>, or <kbd>Enter</kbd> | <kbd>A</kbd> / <kbd>✕</kbd> Button | Confirm / Investigate / Advance dialog |
| **[B] Button** | <kbd>X</kbd> or <kbd>Esc</kbd> | <kbd>B</kbd> / <kbd>○</kbd> Button | Back / Cancel / Close subscreen |
| **[L] Shoulder** | <kbd>Q</kbd> | <kbd>LB</kbd> / <kbd>L1</kbd> Bumper | **Quick access to Case Notes / Dossier** |
| **[R] Shoulder** | <kbd>E</kbd> | <kbd>RB</kbd> / <kbd>R1</kbd> Bumper | **Quick access to ACME Crime Computer** |
| **[☼] Light Button** | <kbd>B</kbd> | <kbd>Y</kbd> / <kbd>△</kbd> Button | **Toggle AGS-101 / AGS-001 Screen Light** |
| **START** | <kbd>Enter</kbd> | Start / Options | Begin case from Title Screen |
| **SELECT** | <kbd>Tab</kbd> | Select / Share | Cycle menu options |

---

## 📁 Architecture Overview

* **`project.godot`**: Configured for 240×160 viewport with integer nearest-neighbor pixel scaling and GBA input mappings.
* **`scripts/autoload/database.gd`**: Autoload singleton storing 16 world capitals, 8 V.I.L.E. suspects, 12 treasures, and ranks.
* **`scripts/autoload/sound_manager.gd`**: Autoload procedural 8-bit sound synthesizer generating retro square and noise waves.
* **`scripts/autoload/game_manager.gd`**: Autoload state machine managing procedural cases, flight routing, time countdown, and warrants.
* **`shaders/gba_lcd.gdshader`**: Real-time GBA SP LCD subpixel grid and backlight shader.
* **`scenes/`**:
  - `main.tscn`: Root viewport coordinator with LCD shader overlay.
  - `title_screen.tscn`: Animated Carmen fedora silhouette and title sequence.
  - `city_hub.tscn`: 240×160 world city investigation hub, dialogue box, and action menus.
