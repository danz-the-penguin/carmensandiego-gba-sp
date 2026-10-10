# Project Asset Directory & Resolution Specifications

This document catalogs every visual and audio asset in *Where in the World is Carmen Sandiego? (GBA SP Edition)*, including directory paths, required dimensions, aspect ratios, file formats, and role descriptions.

---

## 📌 Executive Summary of Resolution Requirements

| Category | Primary Directory | Godot Project Directory | Required Resolution | Aspect Ratio | Color Space / Format | Description |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Character & Witness Portraits** | `assets/portraits/` | `godot/assets/portraits/` | **256 × 256 px** | 1:1 Square | 8-bit RGB/RGBA PNG | Suspects, ACME Chief, Carmen Sandiego, and 15 location-based regional witnesses |
| **City Skylines & Panoramas** | `assets/cities/` | `godot/assets/cities/` | **240 × 90 px** | 8:3 Ultrawide | 8-bit RGB/RGBA PNG | 16 world capitals with parallax skylines, kinetic landmarks, and celestial bodies |
| **Passport Immigration Stamps** | `assets/ui/` | `godot/assets/ui/` | **96 × 64 px** | 3:2 Rectangular | 8-bit RGBA PNG | 5 regional border visa stamps awarded on international transit arrival |
| **UI Badges & Logos** | `assets/ui/` | `godot/assets/ui/` | **96 × 64 px** | 3:2 Rectangular | 8-bit RGBA PNG | ACME Detective Badge and Carmen Fedora Insignia Logo |
| **Display Viewport (Modern HD)** | Main Window Canvas | Project Window Settings | **1280 × 720 px** | 16:9 Widescreen | HD Native Window | Modern HD letterbox canvas housing the 3:2 GBA SP chassis with zero text cutoff |
| **Core GBA SP Screen Canvas** | Web Canvas / Sub-viewport | Godot Viewport Sub-rect | **480 × 320 px** | 3:2 (Exact GBA) | 2× Integer Scale | Native 2× scaling of the original 240×160 GBA LCD screen |

---

## 👤 1. Character Portraits (256 × 256)

All character portraits require a **256 × 256 px** resolution. They utilize nearest-neighbor pixel sampling (`texture_filter = 1`) to retain razor-sharp pixel edges on modern displays.

### A. V.I.L.E. Criminal Masterminds & Carmen Sandiego
* **Location:** `assets/portraits/` and `godot/assets/portraits/`
* **Resolution Requirement:** `256 × 256 px`
* **Format:** PNG (RGB or RGBA)

| File Name | Character | Archetype / Key Traits |
| :--- | :--- | :--- |
| `carmen.png` | **Carmen Sandiego** | Crimson fedora, yellow band, scarlet trenchcoat, ruby signet, shadow-draped eyes |
| `scar_graynolt.png` | **Scar Graynolt** | Blonde pompadour, charcoal suit, gold tie, gold cane handle |
| `fast_eddie.png` | **Fast Eddie B.** | Sailor stripes, messy red hair, eyepatch, crooked grin |
| `darlene_dirk.png` | **Darlene Dirk** | Deep-sea wetsuit, cheek scar, brown hair, yellow racing zipper |
| `lady_agatha.png` | **Lady Agatha** | Purple velvet gown, pearl necklace, blonde ringlets, gold monocle |
| `len_bulk.png` | **Len Bulk** | Leather biker jacket, square jaw, buzzcut, cyan sunglasses |
| `nick_brunch.png` | **Nick Brunch** | Classic trenchcoat, bushy mustache, brown fedora, gold pocket watch |
| `katherine_drib.png` | **Katherine Drib** | Aviator jacket, shearling collar, pilot goggles on brow, gold locket |
| `chief.png` | **ACME Police Chief** | Dark police chief uniform, gold five-point star cap badge, gray mustache |

---

### B. Location-Based Regional Witness Portraits
* **Location:** `assets/portraits/` and `godot/assets/portraits/`
* **Resolution Requirement:** `256 × 256 px`
* **Format:** PNG (RGB)

For each of the 5 geographic divisions, 3 professional witness roles are available:

#### 1. Europe (London, Paris, Rome, Athens, Moscow, Reykjavik)
| File Name | Role | Visual Description |
| :--- | :--- | :--- |
| `banker_europe.png` | Financial Witness | Savile Row tailored 3-piece charcoal wool suit, pince-nez monocle, burgundy silk tie, gold Albert pocket watch chain, mahogany bank paneling |
| `pilot_europe.png` | Transit Witness | Continental airline captain peaked service cap with gold bullion laurel wreath crest, 4 gold rank sleeve bars, gold aviator sunglasses |
| `curator_europe.png` | Museum Witness | Brown herringbone tweed professor jacket with suede elbow patches, crimson silk bowtie, round tortoiseshell reading spectacles, brass magnifying glass |

#### 2. East Asia & Himalayas (Tokyo, Beijing, Kathmandu)
| File Name | Role | Visual Description |
| :--- | :--- | :--- |
| `banker_asia.png` | Financial Witness | Modern slate-blue executive suit, thin rimless metallic glasses, golden abacus lapel pin, neon trading floor bokeh |
| `pilot_asia.png` | Transit Witness | Trans-Himalayan carrier pilot, crisp white shirt with 4-bar gold shoulder epaulets, modern aviation headset with boom microphone |
| `curator_asia.png` | Museum Witness | Imperial jade-green silk mandarin collar jacket with gold frog buttons, carved jade medallion on silk cord, scholar bun with jade hairpin |

#### 3. Latin America (Rio, Mexico City)
| File Name | Role | Visual Description |
| :--- | :--- | :--- |
| `banker_latin.png` | Financial Witness | Off-white embroidered linen Guayabera shirt with pintucks, warm tan complexion, thin mustache, gold chain necklace, warm sunlit stucco background |
| `pilot_latin.png` | Transit Witness | Amazonian & Andes bush pilot, distressed cognac leather bomber jacket, cream shearling fleece collar, brass flight goggles on brow, emerald bandana |
| `curator_latin.png` | Museum Witness | Pre-Columbian relic archaeologist, khaki safari vest with cargo pockets, weathered brown felt fedora, brass sighting compass |

#### 4. Africa & Middle East (Cairo, Nairobi)
| File Name | Role | Visual Description |
| :--- | :--- | :--- |
| `banker_africa.png`<br>`banker_africa_mideast.png` | Financial Witness | Royal-blue embroidered Agbada / Kaftan with intricate gold thread filigree, matching Kufi cap, gold bullion signet ring, vaulted bazaar background |
| `pilot_africa.png`<br>`pilot_africa_mideast.png` | Transit Witness | Trans-Sahara sand-khaki flight suit with ACME transit shoulder patch, desert dust goggles slung around neck, patterned keffiyeh scarf |
| `curator_africa.png`<br>`curator_africa_mideast.png` | Museum Witness | Grand Egyptian Museum linen safari jacket, crimson tarboosh / fez with black silk tassel, brass jeweler's loupe monocle |

#### 5. Americas & Global Hubs (New York, San Francisco, Sydney, Default)
| File Name | Role | Visual Description |
| :--- | :--- | :--- |
| `banker_americas.png` | Financial Witness | Wall Street pinstripe power suit, bold crimson silk power tie, gold tie clip, wireless earpiece with cyan LED glint, illuminated skyscraper skyline |
| `pilot_americas.png` | Transit Witness | Trans-Continental double-breasted jumbo jet captain, scrambled-eggs oak leaf visor cap, headset, glass cockpit avionics display |
| `curator_americas.png` | Museum Witness | Modern art museum director, black merino turtleneck sweater, architectural round spectacles, forensic UV art restoration mini-torch |

#### 6. Legacy / Generic Witness Fallbacks
| File Name | Role | Visual Description |
| :--- | :--- | :--- |
| `banker.png` | Generic Banker | Green banker visor, collared shirt, red tie (256 × 256) |
| `pilot.png` | Generic Pilot | Classic airline pilot visor cap, gold wings badge (256 × 256) |
| `curator.png` | Generic Curator | Gray hair scholar, round spectacles, brown tweed jacket (256 × 256) |

---

## 🏙️ 2. City Skylines & Panoramas (240 × 90)

* **Location:** `assets/cities/` and `godot/assets/cities/`
* **Resolution Requirement:** `240 × 90 px`
* **Aspect Ratio:** `8:3`
* **Format:** PNG (RGB or RGBA)

| File Name | Capital / City | Landmark / Visual Features |
| :--- | :--- | :--- |
| `london.png` | London | Big Ben clock tower, Palace of Westminster, Thames evening reflection |
| `paris.png` | Paris | Eiffel Tower iron spire silhouette, Seine riverbanks, twilight sky |
| `rome.png` | Rome | Roman Colosseum stone arches, marble forum silhouettes |
| `moscow.png` | Moscow | Saint Basil's Cathedral onion domes, Red Square battlements |
| `reykjavik.png` | Reykjavik | Hallgrímskirkja church spire, volcanic snow ridges, Aurora Borealis |
| `tokyo.png` | Tokyo | Tokyo Tower red lattice, Mount Fuji backdrop, neon skyscraper bokeh |
| `beijing.png` | Beijing | Forbidden City imperial curved eaves, Great Wall ridgelines |
| `kathmandu.png` | Kathmandu | Swayambhunath golden stupa dome, snow-capped Himalayan peaks |
| `rio.png` | Rio de Janeiro | Christ the Redeemer atop Corcovado, Sugarloaf Mountain, Guanabara Bay |
| `mexicocity.png` | Mexico City | Teotihuacan Sun & Moon step pyramids, volcanic skyline haze |
| `cairo.png` | Cairo | Great Pyramids of Giza, Great Sphinx silhouette, desert dunes |
| `nairobi.png` | Nairobi | Mount Kenya snow summit, acacia tree silhouettes, savanna horizon |
| `newyork.png` | New York | Empire State Building, Chrysler art-deco crown, harbor waters |
| `sanfrancisco.png` | San Francisco | Golden Gate Bridge international-orange towers, bay fog reflections |
| `sydney.png` | Sydney | Sydney Opera House white sail shells, Harbour Bridge arch |
| `default.png` | International Hub | Neo-retro metropolis towers with illuminated window grids |

---

## 🛂 3. Passport Immigration Visas & Badges (96 × 64)

* **Location:** `assets/ui/` and `godot/assets/ui/`
* **Resolution Requirement:** `96 × 64 px`
* **Aspect Ratio:** `3:2`
* **Format:** PNG (RGBA with alpha transparency)

| File Name | Badge / Visa | Visual Elements |
| :--- | :--- | :--- |
| `stamp_europe.png` | European Interpol Star Visa | Double border with 12 gold European stars and bold INTERPOL clearance seal |
| `stamp_asia.png` | East Asia Pacific Crest Visa | Vermilion circular seal with octagonal border and sunburst compass points |
| `stamp_latin.png` | Latin America Sol de Mayo Visa | Radiating 16-ray golden sun emblem with scalloped border framing |
| `stamp_africa.png` | Afro-Arab Stepped Pyramid Visa | Dual-band stepped geometric frame with palm silhouettes and pyramid stamp |
| `stamp_americas.png` | Pan-American Federal Badge Visa | ACME five-point star badge with federal border ribbon and transit eagle crest |
| `fedora_logo.png` | Carmen Fedora Insignia | Classic scarlet fedora silhouette with golden band and shadow bevel |

---

## 🎵 4. Audio Synthesizer & Soundscape Specifications

All in-game audio uses pure procedural synthesis for zero latency and minimal file footprint:

* **Engine:** Godot 4 `AudioStreamWAV` & HTML5 Web Audio API
* **Sample Rate:** 22,050 Hz / 44,100 Hz
* **Bit Depth:** 8-bit / 16-bit PCM
* **Channels:** Independent Monophonic Synthesizers (BGM, Environmental Ambient Foley, UI SFX, Voice Typewriter)
* **Regional Musical Motifs:**
  * **Europe:** Harpsichord & classical strings baroque progression (D-minor / A-major)
  * **Asia:** Pentatonic chime & temple bells motif with wind percussion
  * **Latin America:** Bossa-nova syncopated groove with acoustic nylon-string accents
  * **Africa / MidEast:** Desert oud scale with polyrhythmic darbuka hand-percussion
  * **Americas:** Smooth detective noir walking bassline with muted trumpet square leads

---

## 🖥️ 5. Display & Viewport Configuration

* **Window Resolution:** `1280 × 720 px` (Standard 16:9 720p HD)
* **Active GBA SP Play Area:** `480 × 320 px` (Centered integer scale)
* **Font Specification:** `PressStart2P.ttf` (`antialiasing = 0`, `hinting = 0`, `subpixel_positioning = 0`)
* **Aspect Ratio Guarantee:** Strict 3:2 core rendering inside 16:9 modern letterbox canvas; all text panels, buttons, dialog boxes, and clue matrices have guaranteed zero character cutoff.
