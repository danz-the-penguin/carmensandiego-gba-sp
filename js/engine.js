/**
 * Where in the World is Carmen Sandiego? - Game Boy Advance (GBA) Edition
 * Core Game Engine: Procedural Cases, Crime Computer, Time & GBA L/R Shoulder Controls
 */

class GBACarmenGameEngine {
  constructor(renderer, audio) {
    this.renderer = renderer;
    this.audio = audio;

    // Persistent player profile
    this.profile = this.loadProfile();

    // Tactical ACME Gadgets Inventory (Replenished each case)
    this.gadgetCharges = {
      uv_light: 2,
      gps_tracer: 1,
      lockpick: 2,
      polygraph: 2
    };
    this.activeTrap = null;
    this.trapTimer = null;

    // Game state
    this.state = "TITLE"; // TITLE, BRIEFING, CITY_HUB, SUBSCREEN, ARREST, GAMEOVER
    this.currentCase = null;
    this.currentCityId = null;
    this.hoursLeft = 40;
    this.dayIndex = 0; // 0=MON, 1=TUE, ...
    this.hourOfDay = 9; // 9 = 9:00 AM
    this.warrantSuspect = null;
    this.cluesGathered = [];
    this.computerFilters = { sex: null, hair: null, vehicle: null, hobby: null, feature: null };
    this.currentCaseSeed = "#ACME-1000";
    this.currentShellIndex = 0;

    // Navigation state
    this.menuIndex = 0; // 0=Investigate, 1=Depart, 2=Crime Comp, 3=Dossier
    this.subscreenMode = null; // 'investigate', 'depart', 'computer_filter', 'dossier', 'gadgets', 'museum', 'trap'
    this.subscreenIndex = 0;
    this.subscreenOptions = [];

    // Typewriter effect state
    this.typewriterText = "";
    this.typewriterTarget = "";
    this.typewriterIndex = 0;
    this.typewriterTimer = null;
    this.onTypewriterDone = null;

    // Title animation timer
    this.titleBlink = true;
    this.titleTimer = null;
  }

  loadProfile() {
    try {
      if (typeof localStorage !== "undefined" && localStorage && typeof localStorage.getItem === "function") {
        const saved = localStorage.getItem("carmen_gba_profile");
        if (saved) {
          const parsed = JSON.parse(saved);
          if (!parsed.recoveredTreasures) parsed.recoveredTreasures = [];
          if (parsed.shellIndex !== undefined) this.currentShellIndex = parsed.shellIndex;
          this.applyShellTheme();
          return parsed;
        }
      }
    } catch (e) {
      // Storage not available
    }
    return { casesSolved: 0, rankIndex: 0, recoveredTreasures: [] };
  }

  saveProfile() {
    try {
      if (typeof localStorage !== "undefined" && localStorage && typeof localStorage.setItem === "function") {
        localStorage.setItem("carmen_gba_profile", JSON.stringify(this.profile));
      }
    } catch (e) {
      // Storage not available
    }
  }

  getRank() {
    const solved = this.profile.casesSolved;
    let rank = GAME_RANKS[0];
    for (const r of GAME_RANKS) {
      if (solved >= r.requiredCases) {
        rank = r;
      }
    }
    return rank;
  }

  cycleShell() {
    const cases = (this.profile && this.profile.casesSolved) || 0;
    const unlocked = [];
    if (typeof GBA_SHELLS !== "undefined") {
      GBA_SHELLS.forEach((s, idx) => {
        if (cases >= s.cases) unlocked.push(idx);
      });
    }
    if (unlocked.length === 0) unlocked.push(0);

    const curPos = unlocked.indexOf(this.currentShellIndex);
    if (curPos === -1) {
      this.currentShellIndex = unlocked[0];
    } else {
      this.currentShellIndex = unlocked[(curPos + 1) % unlocked.length];
    }

    if (this.profile) {
      this.profile.shellIndex = this.currentShellIndex;
      this.saveProfile();
    }
    this.audio.shoulderTrigger();
    this.applyShellTheme();
    return (typeof GBA_SHELLS !== "undefined" && GBA_SHELLS[this.currentShellIndex]) || { name: "PLATINUM SILVER" };
  }

  applyShellTheme() {
    if (typeof document === "undefined") return;
    const consoleEl = document.querySelector(".sp-console");
    if (!consoleEl || typeof GBA_SHELLS === "undefined") return;
    const shell = GBA_SHELLS[this.currentShellIndex] || GBA_SHELLS[0];
    GBA_SHELLS.forEach((s) => consoleEl.classList.remove(`shell-${s.id}`));
    if (shell.id !== "platinum") {
      consoleEl.classList.add(`shell-${shell.id}`);
    }
  }

  // --- Title Screen Loop ---
  initTitleScreen() {
    this.state = "TITLE";
    this.audio.stopBGM();
    if (this.titleTimer) clearInterval(this.titleTimer);

    const lcd = document.getElementById("lcd-screen");
    if (lcd) lcd.classList.add("fullscreen-title");

    this.titleTimer = setInterval(() => {
      this.titleBlink = !this.titleBlink;
      if (this.state === "TITLE") {
        this.renderer.drawTitleScene(this.titleBlink);
      }
    }, 450);

    this.renderer.drawTitleScene(true);
    this.setDialog("PRESS START or [A] to report to ACME Detective HQ!");
    this.updateStatusDisplay("ACME HQ", "STANDBY", `RANK: ${this.getRank().title}`);
  }

  // --- Start a New Procedural Case ---
  startNewCase() {
    if (this.titleTimer) clearInterval(this.titleTimer);
    const lcd = document.getElementById("lcd-screen");
    if (lcd) lcd.classList.remove("fullscreen-title");
    const rank = this.getRank();

    // 1. Pick a stolen treasure & starting city
    const treasure = TREASURES_DATA[Math.floor(Math.random() * TREASURES_DATA.length)];
    const startCityId = treasure.city;

    // 2. Pick a criminal (Ace rank: Carmen Sandiego 60% chance)
    let criminal = SUSPECTS_DATA[Math.floor(Math.random() * SUSPECTS_DATA.length)];
    if (rank.title === "ACE DETECTIVE" && Math.random() < 0.6) {
      criminal = SUSPECTS_DATA.find((s) => s.id === "carmen");
    }

    // 3. Generate trail of cities based on rank hops
    const trail = [startCityId];
    let curr = startCityId;
    for (let i = 0; i < rank.hops; i++) {
      const cityData = CITIES_DATA[curr];
      const validConnections = cityData.connections.filter((id) => !trail.includes(id));
      const nextCityId = validConnections.length > 0
        ? validConnections[Math.floor(Math.random() * validConnections.length)]
        : cityData.connections[Math.floor(Math.random() * cityData.connections.length)];
      trail.push(nextCityId);
      curr = nextCityId;
    }

    // 4. Generate city clue assignments
    const cityClues = {};
    for (let i = 0; i < trail.length - 1; i++) {
      const thisCity = trail[i];
      const nextCity = trail[i + 1];
      const nextData = CITIES_DATA[nextCity];

      const pronounSubj = criminal.sex === "Female" ? "She" : "He";
      const pronounPoss = criminal.sex === "Female" ? "her" : "his";
      const pronounObj = criminal.sex === "Female" ? "her" : "him";

      const suspectTraits = [
        `Witness reported ${pronounSubj.toLowerCase()} had striking ${criminal.hair.toUpperCase()} hair.`,
        `${pronounSubj} sped off in a sleek ${criminal.vehicle.toUpperCase()}.`,
        `Witness heard ${pronounObj} talking about playing ${criminal.hobby.toUpperCase()}.`,
        `${pronounSubj} was seen wearing a ${criminal.feature.toUpperCase()}!`
      ];

      const geoClues = [
        `Teller: "Exchanged funds for ${nextData.currency.toUpperCase()}!"`,
        `Agent: "Departed for a destination with ${nextData.flagDescription.toUpperCase()}."`,
        `Witness: "Heard them speak ${nextData.language.toUpperCase()}."`,
        `Pilot: "Mentioned flying towards ${nextData.landmark.toUpperCase()}!"`,
        `Guide: "Inquired about ${nextData.geography.toUpperCase()}."`
      ];

      const shuffledGeo = [...geoClues].sort(() => 0.5 - Math.random());
      const selectedSuspectTrait = suspectTraits[i % suspectTraits.length];

      cityClues[thisCity] = [
        shuffledGeo[0],
        shuffledGeo[1],
        selectedSuspectTrait
      ];
    }

    // Final city is the hideout
    const finalCity = trail[trail.length - 1];
    cityClues[finalCity] = [
      `Hideout Guard: "You're too late! But wait... someone is cornered inside!"`,
      `Locals whisper: "A suspicious person matching the V.I.L.E. profile is trapped!"`,
      `ACME Agent: "We have the hideout surrounded! Ensure you have an arrest warrant!"`
    ];

    this.currentCase = {
      treasure: treasure.name,
      criminal: criminal,
      trail: trail,
      finalCity: finalCity,
      clues: cityClues
    };

    this.currentCityId = startCityId;
    this.hoursLeft = rank.deadlineHours;
    this.dayIndex = 0;
    this.hourOfDay = 9;
    this.warrantSuspect = null;
    this.cluesGathered = [];
    this.computerFilters = { sex: null, hair: null, vehicle: null, hobby: null, feature: null };
    this.currentCaseSeed = "#ACME-" + Math.floor(1000 + Math.random() * 9000);

    const solved = (this.profile && this.profile.casesSolved) || 0;
    const baseUV = 2 + (solved >= 2 ? 1 : 0) + (solved >= 8 ? 1 : 0) + (solved >= 12 ? 1 : 0);
    const baseGPS = 1 + (solved >= 5 ? 1 : 0) + (solved >= 12 ? 1 : 0);
    const baseLock = 2 + (solved >= 2 ? 1 : 0) + (solved >= 8 ? 1 : 0) + (solved >= 12 ? 1 : 0);
    const basePoly = 2 + (solved >= 5 ? 1 : 0) + (solved >= 12 ? 1 : 0);
    this.gadgetCharges = {
      uv_light: baseUV,
      gps_tracer: baseGPS,
      lockpick: baseLock,
      polygraph: basePoly
    };

    // Go to briefing screen
    this.state = "BRIEFING";
    this.audio.confirm();
    this.audio.startBGM();
    this.renderer.drawBriefingScene();

    const briefingText = `ACME HQ ALERT: ${treasure.name} was stolen from ${CITIES_DATA[startCityId].name}! Suspect spotted fleeing. You have ${this.hoursLeft} hours to track them down and secure a warrant!`;
    this.typewrite(briefingText, () => {
      this.setDialog(briefingText + " [PRESS A]");
    });

    this.updateStatusDisplay(CITIES_DATA[startCityId].name, "MON 9:00AM", `${this.hoursLeft}H LEFT`);
  }

  // --- City Hub View ---
  enterCityHub() {
    this.state = "CITY_HUB";
    this.subscreenMode = null;
    const city = CITIES_DATA[this.currentCityId];
    this.renderer.drawCitySkyline(city.skyline, this.hourOfDay);
    this.updateTimeDisplay();

    // Adapt dynamic regional music and ambient foley
    const region = this.audio.getRegionForCity(this.currentCityId);
    this.audio.startBGM(region);

    // Check if player arrived in final city or cold trail
    const trail = this.currentCase.trail;
    if (!trail.includes(this.currentCityId)) {
      this.audio.cancel();
      this.setDialog(`[ACME ALERT: COLD TRAIL] Local Interpol branches in ${city.name} report ZERO suspect activity! You are off the trail! Use the ACME Casebook [L] or deploy GPS Tracer [G] to reacquire the target!`);
    } else if (this.currentCityId === this.currentCase.finalCity) {
      this.audio.suspenseEncounter();
      this.setDialog(`[ACME DISPATCH: CORNERED!] Visual confirmation! Suspect is hiding in ${city.name} right now! Secure an arrest warrant [R] and investigate the hideout!`);
    } else {
      this.setDialog(`Arrived in ${city.name}. Question witnesses or check connections.`);
    }

    this.updateMenuHighlight();
  }

  // --- Time Management ---
  spendHours(hours) {
    this.hoursLeft = Math.max(0, this.hoursLeft - hours);
    this.hourOfDay += hours;

    const days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];

    while (this.hourOfDay >= 24) {
      this.hourOfDay -= 24;
      this.dayIndex = (this.dayIndex + 1) % days.length;
    }

    // Bedtime penalty: between 10 PM (22) and 6 AM (6)
    if (this.hourOfDay >= 22 || this.hourOfDay < 6) {
      this.hoursLeft = Math.max(0, this.hoursLeft - 8);
      this.hourOfDay = 6;
      this.audio.cancel();
      this.setDialog("Nightfall! Detective rests at a local hotel for 8 hours of required sleep...");
    }

    this.updateTimeDisplay();

    if (this.hoursLeft <= 0) {
      this.triggerGameOver();
      return false;
    }
    return true;
  }

  updateTimeDisplay() {
    const days = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"];
    const dayStr = days[this.dayIndex];
    const ampm = this.hourOfDay >= 12 ? "PM" : "AM";
    const displayHour = this.hourOfDay % 12 === 0 ? 12 : this.hourOfDay % 12;
    const timeStr = `${dayStr} ${displayHour}${ampm}`;
    const cityStr = CITIES_DATA[this.currentCityId] ? CITIES_DATA[this.currentCityId].name : "ACME";

    let trail = { text: "● HOT TRAIL", color: "#34d399" };
    if (this.currentCase && this.currentCase.trail) {
      if (this.currentCityId === this.currentCase.finalCity) {
        trail = { text: "★ CORNERED!", color: "#ef4444" };
      } else if (this.currentCase.trail.includes(this.currentCityId)) {
        trail = { text: "● HOT TRAIL", color: "#34d399" };
      } else {
        trail = { text: "▲ COLD TRAIL", color: "#f87171" };
      }
    }

    this.updateStatusDisplay(cityStr, timeStr, `${this.hoursLeft}H LEFT`, trail);
  }

  // --- Subscreen Management ---
  openInvestigateSubscreen() {
    this.subscreenMode = "investigate";
    this.subscreenIndex = 0;
    const city = CITIES_DATA[this.currentCityId];
    this.subscreenOptions = city.places.map((p, i) => ({
      title: `${i + 1}. ${p.name}`,
      data: p,
      index: i
    }));
    this.subscreenOptions.push({
      title: "🔍 4. SWEEP CRIME SCENE (MAGNIFYING LENS)",
      isInspect: true
    });
    this.renderSubscreen("INVESTIGATE LOCATIONS", this.subscreenOptions);
  }

  openRadioIntercept() {
    this.subscreenMode = "radio";
    this.subscreenIndex = 0;
    this.audio.shoulderTrigger();
    const suspect = this.currentCase.criminal;
    const trail = this.currentCase.trail;
    const currIdx = trail.indexOf(this.currentCityId);
    const nextCityId = currIdx !== -1 && currIdx < trail.length - 1 ? trail[currIdx + 1] : null;

    let lead = `SUSPECT SURVEILLANCE: Vehicle logged as a ${suspect.vehicle || "Convertible"}, with a ${suspect.feature || "Ruby Ring"}!`;
    if (nextCityId && CITIES_DATA[nextCityId]) {
      const nc = CITIES_DATA[nextCityId];
      lead = `V.I.L.E. INTERCEPT: Operative ticketed for ${nc.name} (${nc.country})! Local currency: ${nc.currency}.`;
    }

    this.audio.radioLock();
    const entry = `[RADIO INTERCEPT] ${lead}`;
    if (!this.cluesGathered.includes(entry)) {
      this.cluesGathered.push(entry);
    }
    this.subscreenOptions = [
      { title: "★ SIGNAL LOCKED (96.4 MHz) ★" },
      { title: lead },
      { title: "▶ PRESS [B] TO RETURN TO HQ" }
    ];
    this.renderSubscreen("📻 ACME SURVEILLANCE RADIO RECEIVER", this.subscreenOptions);
  }

  openCrimeSceneInspection() {
    this.subscreenMode = "inspect";
    this.subscreenIndex = 0;
    this.audio.ping();
    const suspect = this.currentCase.criminal;
    const trail = this.currentCase.trail;
    const currIdx = trail.indexOf(this.currentCityId);
    const nextCityId = currIdx !== -1 && currIdx < trail.length - 1 ? trail[currIdx + 1] : null;

    let lead = `PHYSICAL TRACE: Evidence matches suspect hobby (${suspect.hobby || "Tennis"}) and feature (${suspect.feature || "Ruby Ring"})!`;
    if (nextCityId && CITIES_DATA[nextCityId]) {
      const nc = CITIES_DATA[nextCityId];
      lead = `RECOVERED TRAVEL DOC: Boarding slip stamped for flight to ${nc.name} (${nc.landmark})!`;
    }

    const maxH = (this.getRank() && this.getRank().deadlineHours) || 48;
    this.hoursLeft = Math.min(maxH, this.hoursLeft + 2);
    this.updateTimeDisplay();
    const entry = `[PHYSICAL EVIDENCE] ${lead}`;
    if (!this.cluesGathered.includes(entry)) {
      this.cluesGathered.push(entry);
    }

    this.subscreenOptions = [
      { title: "★ EVIDENCE DETECTED WITH MAGNIFYING LENS ★" },
      { title: lead },
      { title: "+2 HOURS TIME BONUS CREDITED TO TIMELINE!" },
      { title: "▶ PRESS [B] TO RETURN TO HQ" }
    ];
    this.renderSubscreen("🔍 CRIME SCENE PHYSICAL INSPECTION", this.subscreenOptions);
  }


  openDepartSubscreen() {
    this.subscreenMode = "depart";
    this.subscreenIndex = 0;
    const city = CITIES_DATA[this.currentCityId];
    this.subscreenOptions = city.connections.map((cId) => ({
      title: `✈ FLY TO ${CITIES_DATA[cId].name}`,
      cityId: cId
    }));
    this.renderSubscreen("DEPART FLIGHTS", this.subscreenOptions);
  }

  openCrimeComputerSubscreen() {
    this.subscreenMode = "computer_filter";
    this.subscreenIndex = 0;
    this.subscreenOptions = [
      { key: "sex", label: "SEX", values: ["Any", "Female", "Male"] },
      { key: "hair", label: "HAIR", values: ["Any", "Red", "Black", "Blonde", "Brown"] },
      { key: "vehicle", label: "VEHICLE", values: ["Any", "Convertible", "Motorcycle", "Limousine"] },
      { key: "hobby", label: "HOBBY", values: ["Any", "Tennis", "Mountain Climbing", "Croquet", "Bowling", "Skydiving", "Sailing", "Scuba Diving"] },
      { key: "feature", label: "FEATURE", values: ["Any", "Ruby Ring", "Tattoo", "Monocle", "Gold Watch", "Gold Locket", "Eyepatch", "Scar", "Cane"] },
      { key: "compute", label: "▶ COMPUTE & ISSUE WARRANT" }
    ];
    this.renderCrimeComputerFilters();
  }

  renderCrimeComputerFilters() {
    const items = this.subscreenOptions.map((opt) => {
      if (opt.key === "compute") {
        return { title: opt.label, key: "compute" };
      }
      const val = this.computerFilters[opt.key] || "Any";
      return { title: `${opt.label}: ${val}`, key: opt.key };
    });
    this.renderSubscreen("CRIME COMPUTER [R]", items);
  }

  openDossierSubscreen() {
    this.subscreenMode = "dossier";
    this.subscreenIndex = 0;
    const warrantTitle = this.warrantSuspect
      ? `★ WARRANT ISSUED: ${this.warrantSuspect.name}`
      : "WARRANT: NONE ISSUED YET";

    const shell = (typeof GBA_SHELLS !== "undefined" ? GBA_SHELLS[this.currentShellIndex] : null) || { name: "PLATINUM SILVER" };
    const reg = (this.audio && this.audio.getRegionForCity(this.currentCityId)) || "americas";
    const items = [
      { title: `★ CASE SEED: ${this.currentCaseSeed} | JURISDICTION: ${reg.toUpperCase()}` },
      { title: `★ STATUS: ${warrantTitle} | STOLEN: ${this.currentCase.treasure}` },
      { title: `🎨 [C] GBA SP SHELL: ${shell.name} (Click to Cycle)`, action: "cycle_shell" },
      { title: "⚡ [G] ACME GADGET BELT (Deploy GPS, UV, Polygraph, Lockpick)", action: "gadgets" },
      { title: "🏛 [V] EVIDENCE HALL & MUSEUM (Recovered Relics)", action: "museum" },
      { title: "--- 🎯 DEDUCTION MATRIX: SUSPECT PROBABILITY ---" }
    ];

    const gatheredLower = this.cluesGathered.join(" ").toLowerCase();
    const suspectScores = [];

    SUSPECTS_DATA.forEach((s) => {
      const matchedTraits = [];
      const conflictTraits = [];

      // Check sex
      if (gatheredLower.includes("she ") || gatheredLower.includes("her ")) {
        if (s.sex.toLowerCase() === "female") {
          matchedTraits.push("Sex: Female");
        } else {
          conflictTraits.push("Sex (Male)");
        }
      } else if (gatheredLower.includes("he ") || gatheredLower.includes("him ") || gatheredLower.includes("his ")) {
        if (s.sex.toLowerCase() === "male") {
          matchedTraits.push("Sex: Male");
        } else {
          conflictTraits.push("Sex (Female)");
        }
      }

      // Check hair
      if (gatheredLower.includes(s.hair.toLowerCase() + " hair") || gatheredLower.includes("dyed " + s.hair.toLowerCase())) {
        matchedTraits.push("Hair: " + s.hair);
      } else if (gatheredLower.includes("red hair") || gatheredLower.includes("black hair") || gatheredLower.includes("blonde hair") || gatheredLower.includes("brown hair")) {
        conflictTraits.push("Hair");
      }

      // Check vehicle
      if (gatheredLower.includes(s.vehicle.toLowerCase())) {
        matchedTraits.push("Vehicle: " + s.vehicle);
      } else if (gatheredLower.includes("convertible") || gatheredLower.includes("motorcycle") || gatheredLower.includes("limousine")) {
        conflictTraits.push("Vehicle");
      }

      // Check hobby
      if (gatheredLower.includes(s.hobby.toLowerCase())) {
        matchedTraits.push("Hobby: " + s.hobby);
      }

      // Check feature
      if (gatheredLower.includes(s.feature.toLowerCase())) {
        matchedTraits.push("Feature: " + s.feature);
      }

      let score = matchedTraits.length * 25;
      if (conflictTraits.length > 0) score = 0;

      suspectScores.push({
        suspect: s,
        score: score,
        matched: matchedTraits,
        conflict: conflictTraits
      });
    });

    suspectScores.sort((a, b) => b.score - a.score);

    suspectScores.forEach((entry) => {
      const s = entry.suspect;
      const score = entry.score;
      const prefix = score >= 50 ? "★" : (score > 0 ? "●" : "✖");
      let note = "";
      if (score > 0) {
        note = `[${score}% MATCH] ${entry.matched.join(", ")} (Click to load in Crime Comp)`;
      } else if (entry.conflict.length > 0) {
        note = `[ELIMINATED] Conflicts: ${entry.conflict.join(", ")}`;
      } else {
        note = `[POSSIBLE] No direct clues yet`;
      }
      items.push({
        title: `${prefix} ${s.name} - ${note}`,
        action: "load_suspect",
        suspect: s
      });
    });

    items.push({ title: "--- 📑 ACTIVE CLUE & INTERCEPT LOG ---" });
    if (this.cluesGathered.length === 0) {
      items.push({ title: "No clues gathered yet. Question witnesses or scan crime scenes!" });
    } else {
      this.cluesGathered.forEach((c) => {
        items.push({ title: `> ${c}` });
      });
    }

    this.subscreenOptions = items;
    this.renderSubscreen("ACME CASEBOOK & DEDUCTION MATRIX [L]", items);
  }

  openGadgets() {
    this.subscreenMode = "gadgets";
    this.subscreenIndex = 0;
    const g = this.gadgetCharges;
    this.subscreenOptions = [
      {
        title: `⚡ GPS MICRO-TRACER [${g.gps_tracer} BATTERY]\n   Ping satellite for suspect flight destination.`,
        gadgetId: "gps_tracer"
      },
      {
        title: `⚡ UV BLACKLIGHT SCANNER [${g.uv_light} BATTERY]\n   Fluorescent beam scans for hidden trait evidence.`,
        gadgetId: "uv_light"
      },
      {
        title: `⚡ ELECTRONIC LOCKPICK [${g.lockpick} BATTERY]\n   Bypasses transit security (+3 Hours saved).`,
        gadgetId: "lockpick"
      },
      {
        title: `⚡ POCKET POLYGRAPH [${g.polygraph} BATTERY]\n   Voice stress test extracts suspect trait.`,
        gadgetId: "polygraph"
      },
      {
        title: "◀ CLOSE GADGET BELT",
        gadgetId: "back"
      }
    ];
    this.renderSubscreen("ACME TACTICAL GADGET BELT", this.subscreenOptions);
  }

  useGadget(gadgetId) {
    if (gadgetId === "back") {
      this.closeSubscreen();
      return;
    }

    const charges = this.gadgetCharges[gadgetId] || 0;
    if (charges <= 0) {
      this.audio.cancel();
      this.closeSubscreen();
      this.setDialog("BATTERY DEPLETED! No charges remaining. Gadgets recharge automatically on your next case assignment.");
      return;
    }

    this.gadgetCharges[gadgetId]--;
    this.audio.gadget();
    this.closeSubscreen();

    const lcd = document.getElementById("lcd-screen");
    if (lcd) {
      lcd.classList.add("screen-shake");
      setTimeout(() => lcd.classList.remove("screen-shake"), 250);
    }

    if (gadgetId === "gps_tracer") {
      const trail = this.currentCase.trail;
      const currIdx = trail.indexOf(this.currentCityId);
      if (currIdx !== -1 && currIdx < trail.length - 1) {
        const nextId = trail[currIdx + 1];
        const nextData = CITIES_DATA[nextId];
        const intel = `[GPS SATELLITE FIX] Micro-tracer transponder tracked to ${nextData.name}, ${nextData.country.toUpperCase()}!`;
        if (!this.cluesGathered.includes(intel)) this.cluesGathered.push(intel);
        this.setDialog(`[GPS TRACER] Satellite link confirmed! Transponder signals indicate suspect boarded a flight bound for ${nextData.name} (${nextData.country})!`);
      } else if (currIdx === trail.length - 1) {
        this.setDialog("[GPS TRACER] SIGNAL MAXIMUM! Suspect is hiding in THIS city right now! Obtain a warrant and corner them!");
      } else {
        this.setDialog("[GPS TRACER] Signal out of range! The suspect did not transit through this city. You are off the trail!");
      }
    } else if (gadgetId === "uv_light") {
      const suspect = this.currentCase.criminal;
      const traits = [
        `suspect left hair strands dyed ${suspect.hair}`,
        `tire tread residue matches a ${suspect.vehicle}`,
        `metallic scrape matches a ${suspect.feature}`
      ];
      const picked = traits[Math.floor(Math.random() * traits.length)];
      const intel = `[UV SCAN] Blacklight revealed fluorescent residue: ${picked}!`;
      if (!this.cluesGathered.includes(intel)) this.cluesGathered.push(intel);
      this.setDialog(`[UV BLACKLIGHT] High-intensity ultraviolet sweep detected trace forensic residue: ${picked}!`);
    } else if (gadgetId === "lockpick") {
      this.hoursLeft = Math.min(this.getRank().deadlineHours, this.hoursLeft + 3);
      this.updateTimeDisplay();
      this.setDialog("[ACME LOCKPICK] Electronic decoder bypassed VIP customs gates and tarmac security! Saved +3 Hours on the investigation clock!");
    } else if (gadgetId === "polygraph") {
      const suspect = this.currentCase.criminal;
      const traits = [
        `witness confirms suspect has a ${suspect.feature}`,
        `polygraph analysis confirms suspect is into ${suspect.hobby}`,
        `voice stress pattern confirms suspect is ${suspect.sex}`
      ];
      const picked = traits[Math.floor(Math.random() * traits.length)];
      const intel = `[POLYGRAPH INTEL] Lie detector cross-examination: ${picked}!`;
      if (!this.cluesGathered.includes(intel)) this.cluesGathered.push(intel);
      this.setDialog(`[POCKET POLYGRAPH] Biometric sensors detected elevated perspiration and voice tremor: ${picked}!`);
    }
  }

  openMuseum() {
    this.subscreenMode = "museum";
    this.subscreenIndex = 0;
    this.audio.confirm();

    const recovered = this.profile.recoveredTreasures || [];
    let recoveredCount = 0;

    const items = TREASURES_DATA.map((t) => {
      const rec = recovered.find((r) => r.name === t.name);
      if (rec) {
        recoveredCount++;
        return {
          title: `★ ${t.name} (RECOVERED)\n   Recovered from ${rec.thief}! Value: ${t.value}\n   ${t.lore}`
        };
      } else {
        const cityData = CITIES_DATA[t.city];
        const cityName = cityData ? cityData.name : "UNKNOWN";
        return {
          title: `🔒 ${t.name} (STOLEN)\n   Missing from ${cityName}. Value: ${t.value}\n   Apprehend culprit to restore to ACME vault.`
        };
      }
    });

    items.push({ title: "◀ PRESS [B] TO RETURN TO HQ" });
    this.subscreenOptions = items;
    this.renderSubscreen(`🏛 ACME EVIDENCE VAULT (${recoveredCount}/${TREASURES_DATA.length} RECOVERED)`, items);
  }

  triggerTrap(placeOpt, continueClue) {
    const types = ["smoke", "blackout", "decoy"];
    const type = types[Math.floor(Math.random() * types.length)];
    this.activeTrap = {
      type: type,
      placeOpt: placeOpt,
      continueClue: continueClue,
      resolved: false
    };
    this.subscreenMode = "trap";
    this.subscreenIndex = 0;
    this.audio.siren();

    const lcd = document.getElementById("lcd-screen");
    if (lcd) {
      lcd.classList.add("screen-shake");
      setTimeout(() => lcd.classList.remove("screen-shake"), 300);
    }

    let title = "";
    let desc = "";
    let hint = "";
    if (type === "smoke") {
      title = "⚡ V.I.L.E. SMOKE AMBUSH! ⚡";
      desc = "Henchman popped a toxic smoke canister! You're losing visibility!";
      hint = "PRESS [B] OR ESC TO DIVE & VAULT CLEAR!";
    } else if (type === "blackout") {
      title = "⚡ CIRCUIT SABOTAGE! BLACKOUT! ⚡";
      desc = "Power grid cut! Pitch black room! Footsteps are fading into the shadows!";
      hint = "PRESS [A] OR SPACE TO DEPLOY ACME UV BLACKLIGHT!";
    } else if (type === "decoy") {
      title = "⚡ SUSPICIOUS WITNESS DETECTED! ⚡";
      desc = "Informant is stammering nervously and whispering into a hidden earpiece!";
      hint = "PRESS [A] OR SPACE TO DEPLOY POCKET LIE DETECTOR!";
    }

    this.subscreenOptions = [
      { title: desc },
      { title: `▶ ${hint}` },
      { title: "⏱ [2.5 SECONDS TO REACT!]" }
    ];
    this.renderSubscreen(title, this.subscreenOptions);

    if (this.trapTimer) clearTimeout(this.trapTimer);
    this.trapTimer = setTimeout(() => {
      this.resolveTrap(false);
    }, 2500);
  }

  resolveTrap(success) {
    if (!this.activeTrap || this.activeTrap.resolved) return;
    this.activeTrap.resolved = true;
    if (this.trapTimer) {
      clearTimeout(this.trapTimer);
      this.trapTimer = null;
    }

    const trap = this.activeTrap;
    const suspect = this.currentCase.criminal;
    const type = trap.type;

    if (success) {
      this.audio.gadget();
      let bonusClue = "";
      let title = "";
      let msg = "";
      if (type === "smoke") {
        title = "★ NARROW ESCAPE! ★";
        msg = "Clean dive! You rolled under the toxic smoke cloud and cornered the witness!";
      } else if (type === "blackout") {
        title = "★ UV BLACKLIGHT ACTIVATED! ★";
        bonusClue = `Glowing footprints reveal suspect vehicle: ${suspect.vehicle}!`;
        msg = `UV beam illuminates the dark! ${bonusClue}`;
      } else if (type === "decoy") {
        title = "★ V.I.L.E. DECOY EXPOSED! ★";
        bonusClue = `Lie detector spikes! Informant confesses: 'Thief has ${suspect.hair} hair!'`;
        msg = `Voice stress analyzer exposed the plant! ${bonusClue}`;
      }

      if (bonusClue) {
        const intel = `[INTEL] ${bonusClue}`;
        if (!this.cluesGathered.includes(intel)) this.cluesGathered.push(intel);
      }

      this.subscreenOptions = [
        { title: msg },
        { title: "▶ PROCEEDING TO WITNESS QUESTIONING..." }
      ];
      this.renderSubscreen(title, this.subscreenOptions);
    } else {
      this.audio.cancel();
      const penalty = type === "smoke" ? 3 : 2;
      this.hoursLeft = Math.max(1, this.hoursLeft - penalty);
      this.updateTimeDisplay();

      let title = "✖ AMBUSH HIT! ✖";
      let msg = `Disoriented by V.I.L.E. sabotage! Lost ${penalty} hours recovering your bearings!`;
      this.subscreenOptions = [
        { title: msg },
        { title: "▶ PROCEEDING TO WITNESS QUESTIONING..." }
      ];
      this.renderSubscreen(title, this.subscreenOptions);
    }

    setTimeout(() => {
      this.closeSubscreen();
      this.activeTrap = null;
      this.typewrite(trap.continueClue, () => {
        this.setDialog(trap.continueClue);
      });
    }, 1500);
  }

  renderSubscreen(title, items) {
    const overlay = document.getElementById("subscreen-overlay");
    const titleEl = document.getElementById("subscreen-title");
    const listEl = document.getElementById("subscreen-items");

    overlay.classList.add("active");
    titleEl.textContent = title;
    listEl.innerHTML = "";

    items.forEach((it, idx) => {
      const div = document.createElement("div");
      div.className = `subscreen-item ${idx === this.subscreenIndex ? "selected" : ""}`;
      div.textContent = it.title;
      div.addEventListener("click", () => {
        this.audio.cursor();
        this.subscreenIndex = idx;
        this.updateSubscreenSelection();
        this.handleConfirm();
      });
      listEl.appendChild(div);
    });
  }

  updateSubscreenSelection() {
    const listEl = document.getElementById("subscreen-items");
    const children = Array.from(listEl.querySelectorAll(".subscreen-item"));
    children.forEach((el, idx) => {
      el.classList.toggle("selected", idx === this.subscreenIndex);
    });
  }

  closeSubscreen() {
    const overlay = document.getElementById("subscreen-overlay");
    overlay.classList.remove("active");
    this.subscreenMode = null;
    this.audio.cancel();
  }

  // --- Subscreen Confirm Handler ---
  handleSubscreenConfirm() {
    if (this.subscreenMode === "radio" || this.subscreenMode === "inspect" || this.subscreenMode === "museum") {
      this.closeSubscreen();
      return;
    }

    if (this.subscreenMode === "gadgets") {
      const opt = this.subscreenOptions[this.subscreenIndex];
      if (opt) {
        this.useGadget(opt.gadgetId);
      }
      return;
    }

    if (this.subscreenMode === "dossier") {
      const opt = this.subscreenOptions[this.subscreenIndex];
      if (opt && opt.action === "gadgets") {
        this.openGadgets();
        return;
      } else if (opt && opt.action === "museum") {
        this.openMuseum();
        return;
      } else if (opt && opt.action === "cycle_shell") {
        this.cycleShell();
        this.openDossierSubscreen();
        return;
      } else if (opt && opt.action === "load_suspect" && opt.suspect) {
        const s = opt.suspect;
        this.computerFilters = {
          sex: s.sex || null,
          hair: s.hair || null,
          vehicle: s.vehicle || null,
          hobby: s.hobby || null,
          feature: s.feature || null
        };
        this.openCrimeComputerSubscreen();
        return;
      }
      this.closeSubscreen();
      return;
    }

    if (this.subscreenMode === "investigate") {
      const placeOpt = this.subscreenOptions[this.subscreenIndex];
      this.closeSubscreen();

      if (placeOpt.isInspect) {
        this.openCrimeSceneInspection();
        return;
      }

      // Draw witness portrait
      this.renderer.drawWitnessPortrait(placeOpt.data.witness);

      // Spend 2 hours
      if (!this.spendHours(2)) return;

      const isCold = !this.currentCase.trail.includes(this.currentCityId);
      let clueText = "";
      if (isCold) {
        clueText = `COLD TRAIL! Local authorities in ${CITIES_DATA[this.currentCityId].name} confirm zero suspect activity matching V.I.L.E. Backtrack to your previous city!`;
      } else {
        const cityClues = this.currentCase.clues[this.currentCityId];
        clueText = cityClues[placeOpt.index % cityClues.length];

        // Cross-examination & double agent breakdown mechanic (28% chance on valid clues)
        if (Math.random() < 0.28) {
          const s = this.currentCase.criminal;
          const traitsList = [
            `Confessed: 'They drove off in a flashy ${s.vehicle}!'`,
            `Broke down during cross-examination: 'I saw ${s.hair} hair under their disguise!'`,
            `Admitted under pressure: 'They wouldn't stop talking about ${s.hobby}!'`,
            `Slipped up: 'They definitely wore a ${s.feature}!'`
          ];
          const bonus = traitsList[Math.floor(Math.random() * traitsList.length)];
          clueText += `\n\n⚡ CROSS-EXAMINATION SUCCESS: Witness cracked under intense questioning: "${bonus}"`;
        }
      }

      this.audio.clueFound();
      const fullClue = `${placeOpt.data.witness}: ${clueText}`;
      const entry = `[${CITIES_DATA[this.currentCityId].name}] ${clueText}`;
      if (!this.cluesGathered.includes(entry)) {
        this.cluesGathered.push(entry);
      }

      // 22% chance of V.I.L.E. Ambush Trap on non-final cities
      if (Math.random() < 0.22 && this.currentCityId !== this.currentCase.finalCity) {
        this.triggerTrap(placeOpt, fullClue);
        return;
      }

      // If at final city and investigating, check for arrest
      if (this.currentCityId === this.currentCase.finalCity) {
        if (!this.warrantSuspect) {
          const warnClue = `${fullClue} - WARNING: Suspect cornered! Secure a warrant via Crime Computer [R] before arresting!`;
          this.typewrite(warnClue, () => {
            this.setDialog(warnClue);
          });
        } else {
          this.typewrite(fullClue, () => {
            this.setDialog(fullClue);
          });
          setTimeout(() => this.attemptArrest(), 1800);
        }
      } else {
        this.typewrite(fullClue, () => {
          this.setDialog(fullClue);
        });
      }
    } else if (this.subscreenMode === "depart") {
      const flightOpt = this.subscreenOptions[this.subscreenIndex];
      this.closeSubscreen();

      this.audio.travel();
      if (!this.spendHours(4)) return;

      this.currentCityId = flightOpt.cityId;
      const destReg = (this.audio && this.audio.getRegionForCity(this.currentCityId)) || "americas";
      this.audio.confirm();
      this.enterCityHub();
      this.setDialog(`[ACME TRANSIT - ${destReg.toUpperCase()} DIVISION] Arrived in ${CITIES_DATA[this.currentCityId].name}! Regional passport stamp issued.`);
    } else if (this.subscreenMode === "computer_filter") {
      const filterOpt = this.subscreenOptions[this.subscreenIndex];

      if (filterOpt.key === "compute") {
        this.computeWarrant();
      } else {
        const currentVal = this.computerFilters[filterOpt.key];
        const values = filterOpt.values;
        let nextIdx = (values.indexOf(currentVal) + 1) % values.length;
        if (currentVal === null || currentVal === undefined) nextIdx = 1;
        this.computerFilters[filterOpt.key] = values[nextIdx] === "Any" ? null : values[nextIdx];
        this.audio.cursor();
        this.renderCrimeComputerFilters();
      }
    }
  }

  computeWarrant() {
    this.closeSubscreen();
    this.audio.confirm();

    const matches = SUSPECTS_DATA.filter((s) => {
      if (this.computerFilters.sex && s.sex !== this.computerFilters.sex) return false;
      if (this.computerFilters.hair && s.hair !== this.computerFilters.hair) return false;
      if (this.computerFilters.vehicle && s.vehicle !== this.computerFilters.vehicle) return false;
      if (this.computerFilters.hobby && s.hobby !== this.computerFilters.hobby) return false;
      if (this.computerFilters.feature && s.feature !== this.computerFilters.feature) return false;
      return true;
    });

    if (matches.length === 1) {
      this.warrantSuspect = matches[0];
      this.audio.warrantIssued();
      const msg = `MATCH CONFIRMED! ARREST WARRANT ISSUED FOR: ${this.warrantSuspect.name}! Bring them in!`;
      this.typewrite(msg);
    } else if (matches.length > 1) {
      this.audio.cancel();
      const names = matches.map((m) => m.name.split(" ")[0]).join(", ");
      const msg = `CRIME COMPUTER: ${matches.length} suspects match (${names}). Clues too vague! Refine traits.`;
      this.typewrite(msg);
    } else {
      this.audio.cancel();
      const msg = "CRIME COMPUTER: 0 suspects match these traits! Check your notes and adjust criteria.";
      this.typewrite(msg);
    }
  }

  // --- Arrest & Resolution ---
  attemptArrest() {
    this.state = "ARREST";
    const criminal = this.currentCase.criminal;
    const lcd = document.getElementById("lcd-screen");
    if (lcd) {
      lcd.classList.add("screen-shake");
      setTimeout(() => lcd.classList.remove("screen-shake"), 350);
    }

    if (this.warrantSuspect && this.warrantSuspect.id === criminal.id) {
      this.audio.victory();
      this.renderer.drawVictoryScene(criminal);

      if (!this.profile.recoveredTreasures) this.profile.recoveredTreasures = [];
      const treasureObj = TREASURES_DATA.find((t) => t.name === this.currentCase.treasure);
      const exists = this.profile.recoveredTreasures.some((r) => r.name === this.currentCase.treasure);
      if (!exists) {
        this.profile.recoveredTreasures.push({
          name: this.currentCase.treasure,
          thief: criminal.name,
          city: this.currentCityId,
          lore: treasureObj ? treasureObj.lore : "Historical world relic.",
          value: treasureObj ? treasureObj.value : "$10,000,000"
        });
      }

      this.profile.casesSolved++;
      this.saveProfile();
      const newRank = this.getRank();

      const victoryMsg = `CASE SOLVED! Warrant verified. You arrested ${criminal.name} and recovered ${this.currentCase.treasure}! Rank: ${newRank.title} (${this.profile.casesSolved} solved). [PRESS A]`;
      this.typewrite(victoryMsg, () => {
        this.setDialog(victoryMsg);
      });
    } else {
      this.audio.cancel();
      this.state = "GAMEOVER";
      this.renderer.drawGameOverScene();

      let failMsg = "";
      if (!this.warrantSuspect) {
        failMsg = `ALERT: You found ${criminal.name}, but you don't have an arrest warrant! Without a warrant, the criminal slipped away! Case Failed.`;
      } else {
        failMsg = `BLUNDER! Your warrant was for ${this.warrantSuspect.name}, but the culprit was ${criminal.name}! V.I.L.E. escapes unpunished! Case Failed.`;
      }

      this.typewrite(failMsg, () => {
        this.setDialog(failMsg + " [PRESS A]");
      });
    }
  }

  triggerGameOver() {
    this.state = "GAMEOVER";
    this.audio.gameOver();
    this.renderer.drawGameOverScene();
    const overMsg = "TIME EXPIRED! The deadline passed and the criminal fled! Case Closed. [PRESS A]";
    this.typewrite(overMsg, () => {
      this.setDialog(overMsg);
    });
  }

  // --- Shoulder Triggers (GBA L & R) ---
  handleTriggerL() {
    this.audio.shoulderTrigger();
    if (this.state !== "CITY_HUB") return;
    if (this.subscreenMode === "dossier") {
      this.closeSubscreen();
    } else {
      this.openDossierSubscreen();
    }
  }

  handleTriggerR() {
    this.audio.shoulderTrigger();
    if (this.state !== "CITY_HUB") return;
    if (this.subscreenMode === "computer_filter") {
      this.closeSubscreen();
    } else {
      this.openCrimeComputerSubscreen();
    }
  }

  handleBrightness() {
    this.audio.lightSwitch();
    const modes = ["mode-ags101-bright", "mode-ags101-normal", "mode-ags001-frontlit"];
    this.brightnessIndex = ((this.brightnessIndex || 0) + 1) % modes.length;
    const lcd = document.getElementById("lcd-screen");
    if (lcd) {
      modes.forEach((m) => lcd.classList.remove(m));
      lcd.classList.add(modes[this.brightnessIndex]);
    }
  }

  // --- Controller Action Handlers ---
  handleConfirm() {
    this.audio.init();

    if (this.typewriterTimer) {
      clearInterval(this.typewriterTimer);
      this.typewriterTimer = null;
      this.setDialog(this.typewriterTarget);
      if (this.onTypewriterDone) this.onTypewriterDone();
      return;
    }

    if (this.state === "TITLE") {
      this.startNewCase();
      return;
    }

    if (this.state === "BRIEFING") {
      this.enterCityHub();
      return;
    }

    if (this.state === "ARREST" || this.state === "GAMEOVER") {
      this.initTitleScreen();
      return;
    }

    if (this.subscreenMode === "trap") {
      if (this.activeTrap && (this.activeTrap.type === "blackout" || this.activeTrap.type === "decoy")) {
        this.resolveTrap(true);
        return;
      }
    }

    if (this.subscreenMode) {
      this.handleSubscreenConfirm();
      return;
    }

    this.audio.confirm();
    if (this.menuIndex === 0) {
      this.openInvestigateSubscreen();
    } else if (this.menuIndex === 1) {
      this.openDepartSubscreen();
    } else if (this.menuIndex === 2) {
      this.openCrimeComputerSubscreen();
    } else if (this.menuIndex === 3) {
      this.openDossierSubscreen();
    } else if (this.menuIndex === 4) {
      this.openRadioIntercept();
    } else if (this.menuIndex === 5) {
      this.openCrimeSceneInspection();
    }
  }

  handleCancel() {
    this.audio.init();
    if (this.subscreenMode === "trap") {
      if (this.activeTrap && this.activeTrap.type === "smoke") {
        this.resolveTrap(true);
      }
      return;
    }
    if (this.subscreenMode) {
      this.closeSubscreen();
    } else {
      this.audio.cancel();
    }
  }

  handleDirection(dir) {
    this.audio.init();
    if (this.subscreenMode) {
      const items = this.subscreenOptions;
      if (!items || items.length === 0) return;

      if (dir === "up") {
        this.subscreenIndex = (this.subscreenIndex - 1 + items.length) % items.length;
      } else if (dir === "down") {
        this.subscreenIndex = (this.subscreenIndex + 1) % items.length;
      }
      this.audio.cursor();
      this.updateSubscreenSelection();
    } else if (this.state === "CITY_HUB") {
      if (dir === "left") this.menuIndex = (this.menuIndex % 3 > 0) ? this.menuIndex - 1 : this.menuIndex + 2;
      else if (dir === "right") this.menuIndex = (this.menuIndex % 3 < 2) ? this.menuIndex + 1 : this.menuIndex - 2;
      else if (dir === "up") this.menuIndex = (this.menuIndex >= 3) ? this.menuIndex - 3 : this.menuIndex + 3;
      else if (dir === "down") this.menuIndex = (this.menuIndex < 3) ? this.menuIndex + 3 : this.menuIndex - 3;
      this.audio.cursor();
      this.updateMenuHighlight();
    }
  }

  handleSelect() {
    this.audio.init();
    if (!this.subscreenMode && this.state === "CITY_HUB") {
      this.menuIndex = (this.menuIndex + 1) % 6;
      this.audio.cursor();
      this.updateMenuHighlight();
    }
  }


  updateMenuHighlight() {
    const menuItems = Array.from(document.querySelectorAll(".menu-item"));
    menuItems.forEach((it, idx) => {
      it.classList.toggle("active", idx === this.menuIndex);
    });
  }

  typewrite(text, onDone = null) {
    if (this.typewriterTimer) clearInterval(this.typewriterTimer);
    this.typewriterTarget = text;
    this.typewriterIndex = 0;
    this.typewriterText = "";
    this.onTypewriterDone = onDone;

    this.typewriterTimer = setInterval(() => {
      if (this.typewriterIndex < this.typewriterTarget.length) {
        this.typewriterText += this.typewriterTarget[this.typewriterIndex];
        this.setDialog(this.typewriterText);
        if (this.typewriterIndex % 2 === 0) {
          this.audio.textBlip();
        }
        this.typewriterIndex++;
      } else {
        clearInterval(this.typewriterTimer);
        this.typewriterTimer = null;
        if (this.onTypewriterDone) this.onTypewriterDone();
      }
    }, 22);
  }

  setDialog(text) {
    const dialogBox = document.getElementById("dialog-box");
    if (dialogBox) {
      dialogBox.textContent = text;
      dialogBox.scrollTop = dialogBox.scrollHeight;
    }
  }

  updateStatusDisplay(city, time, hours, trail = null) {
    const cEl = document.getElementById("txt-city");
    const tEl = document.getElementById("txt-clock");
    const hEl = document.getElementById("txt-hours");
    const trEl = document.getElementById("txt-trail");
    if (cEl) cEl.textContent = city;
    if (tEl) tEl.textContent = time;
    if (hEl) hEl.textContent = hours;
    if (trEl && trail) {
      trEl.textContent = trail.text;
      trEl.style.color = trail.color;
    }
  }
}

if (typeof window !== "undefined") {
  window.GBACarmenGameEngine = GBACarmenGameEngine;
}
if (typeof module !== "undefined" && module.exports) {
  module.exports = { GBACarmenGameEngine };
}
