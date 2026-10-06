/**
 * Where in the World is Carmen Sandiego? - Game Boy Advance (GBA) Edition
 * Pixel Art Renderer (240x160 Native GBA 3:2 Resolution, 15-Bit Full Color)
 */

class GBAGraphicsRenderer {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext("2d");
    this.width = 240;
    this.height = 160;

    // Canvas internal resolution set strictly to 240x160
    this.canvas.width = 240;
    this.canvas.height = 160;

    // Raster PNG asset cache
    this.cityImages = {};
    this.portraitImages = {};
    this.currentCityId = null;
  }

  setResolution(w, h) {
    this.width = w;
    this.height = h;
    if (this.canvas.width !== w) this.canvas.width = w;
    if (this.canvas.height !== h) this.canvas.height = h;
  }

  clear() {
    this.ctx.fillStyle = "#181824";
    this.ctx.fillRect(0, 0, this.width, this.height);
  }

  // --- GBA Title Screen ---
  drawTitleScene(blinkState) {
    this.setResolution(240, 160);
    this.clear();

    // Deep midnight gradient sky
    const sky = this.ctx.createLinearGradient(0, 0, 0, 110);
    sky.addColorStop(0, "#0b0c1e");
    sky.addColorStop(0.6, "#1f1b40");
    sky.addColorStop(1, "#54254b");
    this.ctx.fillStyle = sky;
    this.ctx.fillRect(0, 0, 240, 110);

    // Distant city silhouette with glowing gold windows
    this.ctx.fillStyle = "#100e24";
    for (let x = 0; x < 240; x += 16) {
      const h = 25 + ((x * 13) % 40);
      this.ctx.fillRect(x, 110 - h, 14, h);
      this.ctx.fillStyle = "#ffd166";
      for (let wy = 110 - h + 6; wy < 104; wy += 8) {
        if ((x + wy) % 3 === 0) {
          this.ctx.fillRect(x + 3, wy, 2, 3);
          this.ctx.fillRect(x + 8, wy, 2, 3);
        }
      }
      this.ctx.fillStyle = "#100e24";
    }

    // World globe / moon crescent behind Carmen
    this.ctx.fillStyle = "#f39c12";
    this.ctx.beginPath();
    this.ctx.arc(175, 48, 32, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.fillStyle = "#e67e22";
    this.ctx.beginPath();
    this.ctx.arc(175, 48, 28, 0, Math.PI * 2);
    this.ctx.fill();

    // Carmen Sandiego GBA Sprite (Red fedora, yellow scarf, crimson trench coat)
    this.drawCarmenFigure(155, 30);

    // Title Banners (GBA vibrant arcade typography)
    // Gold & crimson banner
    this.ctx.fillStyle = "#a81c2f";
    this.ctx.fillRect(8, 12, 136, 38);
    this.ctx.lineWidth = 2;
    this.ctx.strokeStyle = "#ffd166";
    this.ctx.strokeRect(8, 12, 136, 38);

    this.ctx.fillStyle = "#ffffff";
    this.ctx.font = '7px "Press Start 2P", monospace';
    this.ctx.fillText("WHERE IN THE WORLD", 14, 24);
    this.ctx.fillText("IS", 14, 34);

    this.ctx.fillStyle = "#ffd166";
    this.ctx.font = '8px "Press Start 2P", monospace';
    this.ctx.fillText("CARMEN SANDIEGO?", 14, 45);

    // GBA Edition Tag
    this.ctx.fillStyle = "#3b82f6";
    this.ctx.fillRect(10, 54, 98, 12);
    this.ctx.fillStyle = "#ffffff";
    this.ctx.font = '6px "Press Start 2P", monospace';
    this.ctx.fillText("ADVANCE EDITION", 14, 63);

    // Bottom banner
    this.ctx.fillStyle = "#0d1117";
    this.ctx.fillRect(0, 110, 240, 50);
    this.ctx.fillStyle = "#1f2937";
    this.ctx.fillRect(0, 110, 240, 2);

    this.ctx.fillStyle = "#94a3b8";
    this.ctx.font = '6px "Press Start 2P", monospace';
    this.ctx.fillText("© ACME DETECTIVE AGENCY / V.I.L.E.", 16, 128);

    if (blinkState) {
      this.ctx.fillStyle = "#ffd166";
      this.ctx.font = '7px "Press Start 2P", monospace';
      this.ctx.fillText("▶ PRESS START / [A] BUTTON", 22, 146);
    }
  }

  drawCarmenFigure(x, y) {
    // Carmen's wide brim fedora (Crimson Red with golden yellow band)
    this.ctx.fillStyle = "#b91c1c";
    this.ctx.beginPath();
    this.ctx.ellipse(x + 20, y + 16, 26, 6, 0, 0, Math.PI * 2);
    this.ctx.fill();

    // Fedora crown
    this.ctx.fillRect(x + 7, y + 2, 26, 14);
    // Yellow hat ribbon
    this.ctx.fillStyle = "#facc15";
    this.ctx.fillRect(x + 7, y + 12, 26, 4);

    // Trench coat collar & silhouette
    this.ctx.fillStyle = "#991b1b";
    this.ctx.fillRect(x + 4, y + 22, 32, 28);
    // Yellow silk scarf
    this.ctx.fillStyle = "#facc15";
    this.ctx.fillRect(x + 14, y + 20, 12, 14);
    this.ctx.fillStyle = "#ca8a04";
    this.ctx.fillRect(x + 18, y + 24, 6, 16);

    // Trench coat lapels
    this.ctx.fillStyle = "#7f1d1d";
    this.ctx.beginPath();
    this.ctx.moveTo(x + 4, y + 22);
    this.ctx.lineTo(x + 16, y + 36);
    this.ctx.lineTo(x + 8, y + 50);
    this.ctx.closePath();
    this.ctx.fill();

    // Face shadow & mysterious eyes
    this.ctx.fillStyle = "#d4a373";
    this.ctx.fillRect(x + 13, y + 15, 14, 7);
    this.ctx.fillStyle = "#451a03";
    this.ctx.fillRect(x + 11, y + 14, 18, 4); // shadow under brim
    this.ctx.fillStyle = "#1e293b";
    this.ctx.fillRect(x + 16, y + 18, 3, 2); // eye glint
  }

  // --- ACME HQ Office Briefing ---
  drawBriefingScene() {
    this.setResolution(240, 88);
    this.clear();

    // Office wallpaper with venetian blinds
    this.ctx.fillStyle = "#1e293b";
    this.ctx.fillRect(0, 0, 240, 88);

    // Window blinds & warm morning sunlight
    this.ctx.fillStyle = "#334155";
    for (let y = 8; y < 60; y += 5) {
      this.ctx.fillRect(16, y, 70, 3);
    }
    // Sunlight ray
    this.ctx.fillStyle = "rgba(255, 230, 140, 0.15)";
    this.ctx.beginPath();
    this.ctx.moveTo(16, 8);
    this.ctx.lineTo(120, 88);
    this.ctx.lineTo(40, 88);
    this.ctx.lineTo(16, 60);
    this.ctx.closePath();
    this.ctx.fill();

    // World map hanging on wall
    this.ctx.fillStyle = "#475569";
    this.ctx.fillRect(130, 8, 80, 40);
    this.ctx.fillStyle = "#94a3b8";
    this.ctx.strokeRect(130, 8, 80, 40);
    // Green continents
    this.ctx.fillStyle = "#15803d";
    this.ctx.fillRect(140, 16, 24, 10);
    this.ctx.fillRect(174, 15, 26, 16);
    this.ctx.fillRect(180, 34, 16, 8);

    // ACME Chief mahogany desk
    this.ctx.fillStyle = "#78350f";
    this.ctx.fillRect(20, 58, 200, 30);
    this.ctx.fillStyle = "#92400e";
    this.ctx.fillRect(16, 54, 208, 6);

    // ACME Chief sprite (Navy suit, red tie, spectacles)
    this.ctx.fillStyle = "#1e3a8a"; // Suit shoulders
    this.ctx.fillRect(95, 40, 50, 24);
    this.ctx.fillStyle = "#ffffff"; // Shirt
    this.ctx.fillRect(112, 40, 16, 14);
    this.ctx.fillStyle = "#dc2626"; // Red tie
    this.ctx.fillRect(117, 44, 6, 18);
    // Head & hair
    this.ctx.fillStyle = "#fbcfe8";
    this.ctx.fillRect(106, 18, 28, 24);
    this.ctx.fillStyle = "#6b7280"; // Silver hair
    this.ctx.fillRect(102, 14, 36, 10);
    this.ctx.fillRect(102, 20, 6, 12);
    this.ctx.fillRect(132, 20, 6, 12);
    // Spectacles
    this.ctx.fillStyle = "#ffd166";
    this.ctx.strokeRect(108, 26, 8, 6);
    this.ctx.strokeRect(124, 26, 8, 6);

    // Rotary telephone & top secret folder
    this.ctx.fillStyle = "#0f172a";
    this.ctx.fillRect(36, 48, 22, 14);
    this.ctx.fillRect(32, 44, 30, 6); // Receiver
    this.ctx.fillStyle = "#fef08a";
    this.ctx.fillRect(170, 50, 30, 14);
    this.ctx.fillStyle = "#dc2626";
    this.ctx.font = '5px "Press Start 2P", monospace';
    this.ctx.fillText("V.I.L.E.", 174, 60);
  }

  // --- Vibrant 15-Bit GBA City Skylines ---
  drawCitySkyline(cityId) {
    this.currentCityId = cityId;
    this.setResolution(240, 88);
    this.clear();

    if (!this.cityImages[cityId]) {
      const img = new Image();
      img.src = `assets/cities/${cityId}.png`;
      img.onload = () => {
        if (this.currentCityId === cityId) this.drawCitySkyline(cityId);
      };
      this.cityImages[cityId] = img;
    }
    const raster = this.cityImages[cityId];
    if (raster && raster.complete && raster.naturalWidth > 0) {
      this.ctx.imageSmoothingEnabled = false;
      this.ctx.drawImage(raster, 0, 0, 240, 88);
      return;
    }

    switch (cityId) {
      case "london":
        // Twilight sky over Thames
        this.drawGradientSky("#1e293b", "#3b82f6", "#cbd5e1");
        // London Big Ben & Parliament in warm stone
        this.ctx.fillStyle = "#b45309";
        this.ctx.fillRect(40, 20, 24, 60);
        this.ctx.fillRect(44, 10, 16, 10);
        this.ctx.fillRect(49, 2, 6, 8); // Spire
        // Illuminated Big Ben clock face
        this.ctx.fillStyle = "#fef08a";
        this.ctx.fillRect(45, 26, 14, 14);
        this.ctx.fillStyle = "#78350f";
        this.ctx.fillRect(51, 31, 2, 5);

        // Westminster palace roofline
        this.ctx.fillStyle = "#78350f";
        this.ctx.fillRect(64, 46, 150, 34);
        for (let i = 70; i < 210; i += 18) {
          this.ctx.fillStyle = "#92400e";
          this.ctx.fillRect(i, 36, 12, 14);
          this.ctx.fillStyle = "#fef08a";
          this.ctx.fillRect(i + 3, 40, 6, 8);
        }

        // River Thames with reflections
        this.ctx.fillStyle = "#1e3a8a";
        this.ctx.fillRect(0, 72, 240, 16);
        this.ctx.fillStyle = "#60a5fa";
        this.ctx.fillRect(20, 76, 200, 2);
        this.ctx.fillRect(50, 81, 140, 2);
        break;

      case "paris":
        // Romantic Parisian sunset sky
        this.drawGradientSky("#4a044e", "#db2777", "#fed7aa");
        // Distant Haussmann buildings
        this.ctx.fillStyle = "#475569";
        this.ctx.fillRect(0, 52, 90, 30);
        this.ctx.fillRect(150, 52, 90, 30);
        // Arc de Triomphe
        this.ctx.fillStyle = "#64748b";
        this.ctx.fillRect(18, 40, 28, 26);
        this.ctx.fillStyle = "#fed7aa";
        this.ctx.fillRect(26, 52, 12, 14);

        // Eiffel Tower (centerpiece)
        this.ctx.fillStyle = "#334155";
        this.ctx.fillRect(118, 4, 4, 30); // Top spire
        this.ctx.beginPath();
        this.ctx.moveTo(120, 30);
        this.ctx.lineTo(95, 80);
        this.ctx.lineTo(145, 80);
        this.ctx.closePath();
        this.ctx.fill();
        // Tower arch cutout
        this.ctx.fillStyle = "#fed7aa";
        this.ctx.beginPath();
        this.ctx.moveTo(120, 48);
        this.ctx.lineTo(106, 80);
        this.ctx.lineTo(134, 80);
        this.ctx.closePath();
        this.ctx.fill();
        // Golden evening street lamps
        this.ctx.fillStyle = "#fef08a";
        this.ctx.fillRect(60, 66, 3, 3);
        this.ctx.fillRect(180, 66, 3, 3);
        break;

      case "cairo":
        // Scorching Sahara Desert Sky & Sun
        this.drawGradientSky("#7c2d12", "#ea580c", "#fde047");
        // Blazing sun
        this.ctx.fillStyle = "#fffbeb";
        this.ctx.beginPath();
        this.ctx.arc(190, 22, 16, 0, Math.PI * 2);
        this.ctx.fill();

        // Great Pyramids in warm sandstone
        this.ctx.fillStyle = "#d97706";
        // Left pyramid
        this.ctx.beginPath();
        this.ctx.moveTo(70, 24);
        this.ctx.lineTo(140, 72);
        this.ctx.lineTo(5, 72);
        this.ctx.closePath();
        this.ctx.fill();
        // Pyramid shaded face
        this.ctx.fillStyle = "#92400e";
        this.ctx.beginPath();
        this.ctx.moveTo(70, 24);
        this.ctx.lineTo(140, 72);
        this.ctx.lineTo(70, 72);
        this.ctx.closePath();
        this.ctx.fill();

        // Second pyramid in background
        this.ctx.fillStyle = "#b45309";
        this.ctx.beginPath();
        this.ctx.moveTo(155, 34);
        this.ctx.lineTo(215, 72);
        this.ctx.lineTo(105, 72);
        this.ctx.closePath();
        this.ctx.fill();

        // Nile river oasis
        this.ctx.fillStyle = "#0284c7";
        this.ctx.fillRect(0, 72, 240, 16);
        this.ctx.fillStyle = "#15803d"; // Palm fronds
        this.ctx.fillRect(20, 62, 18, 12);
        this.ctx.fillRect(210, 60, 20, 14);
        break;

      case "tokyo":
        // Mt Fuji & Modern Neon Skyline
        this.drawGradientSky("#1e1b4b", "#6366f1", "#fbcfe8");

        // Majestic Mount Fuji
        this.ctx.fillStyle = "#312e81";
        this.ctx.beginPath();
        this.ctx.moveTo(120, 12);
        this.ctx.lineTo(195, 65);
        this.ctx.lineTo(45, 65);
        this.ctx.closePath();
        this.ctx.fill();
        // Snow capped peak
        this.ctx.fillStyle = "#ffffff";
        this.ctx.beginPath();
        this.ctx.moveTo(120, 12);
        this.ctx.lineTo(142, 28);
        this.ctx.lineTo(98, 28);
        this.ctx.closePath();
        this.ctx.fill();

        // Traditional Pagoda on left
        this.ctx.fillStyle = "#b91c1c";
        this.ctx.fillRect(30, 36, 32, 5);
        this.ctx.fillRect(36, 30, 20, 7);
        this.ctx.fillRect(26, 46, 40, 5);
        this.ctx.fillRect(32, 40, 28, 7);
        this.ctx.fillRect(20, 56, 52, 6);
        this.ctx.fillRect(28, 50, 36, 7);

        // Tokyo Tower on right (Red & White lattice)
        this.ctx.fillStyle = "#ef4444";
        this.ctx.fillRect(195, 18, 3, 50);
        this.ctx.fillStyle = "#ffffff";
        this.ctx.fillRect(190, 42, 14, 4);
        this.ctx.fillStyle = "#ef4444";
        this.ctx.fillRect(186, 56, 22, 5);

        // Tokyo Ground / Shinjuku street
        this.ctx.fillStyle = "#0f172a";
        this.ctx.fillRect(0, 68, 240, 20);
        // Cherry blossoms
        this.ctx.fillStyle = "#f472b6";
        for (let bx = 10; bx < 230; bx += 32) {
          this.ctx.fillRect(bx, 72, 4, 3);
        }
        break;

      case "newyork":
        // Manhattan sunset over Hudson River
        this.drawGradientSky("#0f172a", "#c2410c", "#fbbf24");

        // Lady Liberty torch and crown
        this.ctx.fillStyle = "#0d9488"; // Copper patina
        this.ctx.fillRect(16, 44, 24, 38);
        this.ctx.fillRect(22, 32, 12, 14);
        this.ctx.fillRect(28, 20, 4, 12); // Torch arm
        this.ctx.fillStyle = "#facc15"; // Torch fire
        this.ctx.fillRect(27, 16, 6, 5);

        // Manhattan Skyscrapers
        for (let x = 50; x < 235; x += 18) {
          const h = 30 + ((x * 17) % 45);
          this.ctx.fillStyle = "#1e293b";
          this.ctx.fillRect(x, 82 - h, 16, h);
          this.ctx.fillStyle = "#fef08a"; // Glowing windows
          for (let wy = 82 - h + 5; wy < 76; wy += 6) {
            this.ctx.fillRect(x + 3, wy, 3, 2);
            this.ctx.fillRect(x + 9, wy, 3, 2);
          }
        }
        // Empire State Spire
        this.ctx.fillStyle = "#475569";
        this.ctx.fillRect(112, 8, 4, 26);
        this.ctx.fillStyle = "#ef4444"; // Red beacon
        this.ctx.fillRect(113, 6, 2, 2);

        // Hudson river
        this.ctx.fillStyle = "#1e3a8a";
        this.ctx.fillRect(0, 78, 240, 10);
        break;

      case "sydney":
        // Sydney Harbor sunny Pacific blue
        this.drawGradientSky("#0369a1", "#38bdf8", "#bae6fd");

        // Sydney Harbor Bridge Steel Arch
        this.ctx.strokeStyle = "#475569";
        this.ctx.lineWidth = 5;
        this.ctx.beginPath();
        this.ctx.arc(52, 78, 42, Math.PI, 0, false);
        this.ctx.stroke();

        // Sydney Opera House (Gleaming white sail shells)
        this.ctx.fillStyle = "#ffffff";
        // Shell 1
        this.ctx.beginPath();
        this.ctx.moveTo(115, 72);
        this.ctx.quadraticCurveTo(135, 34, 155, 72);
        this.ctx.closePath();
        this.ctx.fill();
        // Shell 2
        this.ctx.beginPath();
        this.ctx.moveTo(140, 72);
        this.ctx.quadraticCurveTo(165, 24, 190, 72);
        this.ctx.closePath();
        this.ctx.fill();
        // Shell 3
        this.ctx.beginPath();
        this.ctx.moveTo(175, 72);
        this.ctx.quadraticCurveTo(195, 42, 215, 72);
        this.ctx.closePath();
        this.ctx.fill();

        // Harbor waters
        this.ctx.fillStyle = "#0284c7";
        this.ctx.fillRect(0, 70, 240, 18);
        this.ctx.fillStyle = "#bae6fd";
        this.ctx.fillRect(20, 76, 200, 2);
        break;

      case "rio":
        // Corcovado & Sugarloaf Mountain
        this.drawGradientSky("#065f46", "#059669", "#fef08a");
        // Sugarloaf mountain
        this.ctx.fillStyle = "#047857";
        this.ctx.beginPath();
        this.ctx.ellipse(55, 62, 38, 30, 0, 0, Math.PI * 2);
        this.ctx.fill();

        // Corcovado & Christ Redeemer statue
        this.ctx.fillStyle = "#064e3b";
        this.ctx.fillRect(150, 42, 36, 42);
        this.ctx.fillStyle = "#f8fafc";
        this.ctx.fillRect(165, 22, 6, 22); // Statue body
        this.ctx.fillRect(154, 26, 28, 4); // Outstretched arms

        // Atlantic ocean & Copacabana beach
        this.ctx.fillStyle = "#0284c7";
        this.ctx.fillRect(0, 72, 240, 16);
        this.ctx.fillStyle = "#fef08a"; // Golden sand
        this.ctx.fillRect(0, 70, 240, 3);
        break;

      case "rome":
        // Classical Roman Mediterranean
        this.drawGradientSky("#1e3a8a", "#60a5fa", "#fed7aa");
        // Colosseum in ancient limestone
        this.ctx.fillStyle = "#d97706";
        this.ctx.fillRect(30, 28, 180, 48);
        for (let x = 40; x < 200; x += 18) {
          this.ctx.fillStyle = "#78350f";
          this.ctx.fillRect(x, 36, 10, 16);
          this.ctx.fillRect(x, 56, 10, 16);
        }
        // Cypress pine trees
        this.ctx.fillStyle = "#15803d";
        this.ctx.fillRect(16, 40, 8, 36);
        this.ctx.fillRect(216, 40, 8, 36);
        break;

      default:
        // International metropolis default
        this.drawGradientSky("#0f172a", "#3b82f6", "#cbd5e1");
        this.ctx.fillStyle = "#1e293b";
        for (let x = 10; x < 235; x += 22) {
          const h = 25 + ((x * 19) % 45);
          this.ctx.fillRect(x, 82 - h, 18, h);
          this.ctx.fillStyle = "#fef08a";
          this.ctx.fillRect(x + 4, 82 - h + 6, 4, 4);
          this.ctx.fillStyle = "#1e293b";
        }
        this.ctx.fillStyle = "#334155";
        this.ctx.fillRect(0, 78, 240, 10);
        break;
    }
  }

  drawGradientSky(c1, c2, c3) {
    const sky = this.ctx.createLinearGradient(0, 0, 0, 82);
    sky.addColorStop(0, c1);
    sky.addColorStop(0.6, c2);
    sky.addColorStop(1, c3);
    this.ctx.fillStyle = sky;
    this.ctx.fillRect(0, 0, 240, 84);
  }

  // --- GBA Witness Encounter (Full-Color Portrait Frame) ---
  drawWitnessPortrait(witnessType) {
    this.setResolution(240, 88);
    this.clear();

    // Investigation room background
    this.ctx.fillStyle = "#1e293b";
    this.ctx.fillRect(0, 0, 240, 88);

    // Portrait frame (Center-left)
    this.ctx.fillStyle = "#0f172a";
    this.ctx.fillRect(80, 4, 80, 72);
    this.ctx.strokeStyle = "#ffd166";
    this.ctx.lineWidth = 2;
    this.ctx.strokeRect(80, 4, 80, 72);

    // Background inside portrait
    this.ctx.fillStyle = "#334155";
    this.ctx.fillRect(82, 6, 76, 68);

    const wt = witnessType.toLowerCase();
    let pKey = "banker";
    if (wt.includes("pilot") || wt.includes("flight") || wt.includes("captain")) pKey = "pilot";
    else if (wt.includes("curator") || wt.includes("archaeologist") || wt.includes("historian")) pKey = "curator";

    if (!this.portraitImages[pKey]) {
      const img = new Image();
      img.src = `assets/portraits/${pKey}.png`;
      img.onload = () => this.drawWitnessPortrait(witnessType);
      this.portraitImages[pKey] = img;
    }
    const raster = this.portraitImages[pKey];
    if (raster && raster.complete && raster.naturalWidth > 0) {
      this.ctx.imageSmoothingEnabled = false;
      this.ctx.drawImage(raster, 88, 10, 64, 60);

      // Witness name badge banner below
      this.ctx.fillStyle = "#0f172a";
      this.ctx.fillRect(40, 72, 160, 11);
      this.ctx.fillStyle = "#ffd166";
      this.ctx.font = '6px "Press Start 2P", monospace';
      this.ctx.textAlign = "center";
      this.ctx.fillText(witnessType.toUpperCase(), 120, 80);
      this.ctx.textAlign = "start";
      return;
    }
    if (wt.includes("pilot") || wt.includes("flight") || wt.includes("captain")) {
      // Pilot uniform (Navy blue with gold stripes & visor cap)
      this.ctx.fillStyle = "#1e3a8a";
      this.ctx.fillRect(94, 44, 52, 28);
      this.ctx.fillStyle = "#ffd166"; // Gold lapel wings
      this.ctx.fillRect(116, 48, 8, 4);

      // Pilot cap
      this.ctx.fillStyle = "#1e3a8a";
      this.ctx.fillRect(100, 12, 40, 10);
      this.ctx.fillStyle = "#ffd166"; // Gold braid
      this.ctx.fillRect(100, 20, 40, 3);
      this.ctx.fillStyle = "#0f172a"; // Shiny visor
      this.ctx.fillRect(98, 22, 44, 4);

      // Face
      this.ctx.fillStyle = "#fbcfe8";
      this.ctx.fillRect(104, 25, 32, 20);
      this.ctx.fillStyle = "#1e293b";
      this.ctx.fillRect(110, 32, 4, 3);
      this.ctx.fillRect(126, 32, 4, 3);
    } else if (wt.includes("curator") || wt.includes("archaeologist") || wt.includes("historian")) {
      // Curator with tweed jacket & spectacles
      this.ctx.fillStyle = "#78350f";
      this.ctx.fillRect(94, 44, 52, 28);
      this.ctx.fillStyle = "#fef08a"; // Bowtie
      this.ctx.fillRect(116, 46, 8, 6);

      // Face & glasses
      this.ctx.fillStyle = "#fed7aa";
      this.ctx.fillRect(104, 18, 32, 26);
      this.ctx.fillStyle = "#94a3b8"; // Grey hair
      this.ctx.fillRect(100, 14, 40, 8);
      this.ctx.fillStyle = "#ffd166"; // Golden round spectacles
      this.ctx.strokeRect(108, 26, 8, 6);
      this.ctx.strokeRect(124, 26, 8, 6);
    } else {
      // Professional teller / citizen
      this.ctx.fillStyle = "#0284c7";
      this.ctx.fillRect(94, 44, 52, 28);
      this.ctx.fillStyle = "#ffffff";
      this.ctx.fillRect(114, 44, 12, 14);

      // Face & hair
      this.ctx.fillStyle = "#fed7aa";
      this.ctx.fillRect(104, 18, 32, 26);
      this.ctx.fillStyle = "#451a03"; // Brown hair
      this.ctx.fillRect(100, 12, 40, 10);
      this.ctx.fillStyle = "#1e293b";
      this.ctx.fillRect(110, 28, 4, 3);
      this.ctx.fillRect(126, 28, 4, 3);
    }

    // Witness name badge banner below
    this.ctx.fillStyle = "#0f172a";
    this.ctx.fillRect(40, 72, 160, 11);
    this.ctx.fillStyle = "#ffd166";
    this.ctx.font = '6px "Press Start 2P", monospace';
    this.ctx.textAlign = "center";
    this.ctx.fillText(witnessType.toUpperCase(), 120, 80);
    this.ctx.textAlign = "start";
  }

  // --- Arrest Victory Scene ---
  drawVictoryScene(suspect) {
    this.setResolution(240, 88);
    this.clear();

    // Flashing siren background
    this.ctx.fillStyle = "#1e1b4b";
    this.ctx.fillRect(0, 0, 240, 88);

    // Police flashing red & blue banner
    this.ctx.fillStyle = "#dc2626";
    this.ctx.fillRect(10, 6, 105, 76);
    this.ctx.fillStyle = "#2563eb";
    this.ctx.fillRect(125, 6, 105, 76);

    // Central mugshot / handcuffs frame
    this.ctx.fillStyle = "#0f172a";
    this.ctx.fillRect(50, 10, 140, 68);
    this.ctx.strokeStyle = "#ffd166";
    this.ctx.lineWidth = 2;
    this.ctx.strokeRect(50, 10, 140, 68);

    // Handcuffs icon
    this.ctx.fillStyle = "#cbd5e1";
    this.ctx.beginPath();
    this.ctx.arc(95, 34, 12, 0, Math.PI * 2);
    this.ctx.arc(145, 34, 12, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.fillStyle = "#0f172a";
    this.ctx.beginPath();
    this.ctx.arc(95, 34, 7, 0, Math.PI * 2);
    this.ctx.arc(145, 34, 7, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.fillStyle = "#94a3b8";
    this.ctx.fillRect(105, 32, 30, 4); // Chain

    this.ctx.fillStyle = "#ffd166";
    this.ctx.font = '7px "Press Start 2P", monospace';
    this.ctx.textAlign = "center";
    this.ctx.fillText("APPREHENDED!", 120, 56);
    this.ctx.fillStyle = "#ffffff";
    this.ctx.font = '6px "Press Start 2P", monospace';
    this.ctx.fillText(suspect.name, 120, 68);
    this.ctx.textAlign = "start";
  }

  // --- Game Over / Escape Scene ---
  drawGameOverScene() {
    this.setResolution(240, 88);
    this.clear();

    this.ctx.fillStyle = "#1e1b4b";
    this.ctx.fillRect(0, 0, 240, 88);

    this.ctx.fillStyle = "#0f172a";
    this.ctx.fillRect(20, 10, 200, 68);
    this.ctx.strokeStyle = "#ef4444";
    this.ctx.lineWidth = 2;
    this.ctx.strokeRect(20, 10, 200, 68);

    this.ctx.fillStyle = "#ef4444";
    this.ctx.font = '9px "Press Start 2P", monospace';
    this.ctx.textAlign = "center";
    this.ctx.fillText("TIME EXPIRED!", 120, 34);

    this.ctx.fillStyle = "#cbd5e1";
    this.ctx.font = '7px "Press Start 2P", monospace';
    this.ctx.fillText("SUSPECT ESCAPED!", 120, 48);
    this.ctx.fillStyle = "#94a3b8";
    this.ctx.font = '6px "Press Start 2P", monospace';
    this.ctx.fillText("CASE CLOSED BY CHIEF", 120, 60);
    this.ctx.textAlign = "start";
  }
}

if (typeof window !== "undefined") {
  window.GBAGraphicsRenderer = GBAGraphicsRenderer;
}
if (typeof module !== "undefined" && module.exports) {
  module.exports = { GBAGraphicsRenderer };
}
