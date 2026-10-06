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

    // Navigation state
    this.menuIndex = 0; // 0=Investigate, 1=Depart, 2=Crime Comp, 3=Dossier
    this.subscreenMode = null; // 'investigate', 'depart', 'computer_filter', 'dossier'
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
        if (saved) return JSON.parse(saved);
      }
    } catch (e) {
      // Storage not available
    }
    return { casesSolved: 0, rankIndex: 0 };
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

      const suspectTraits = [
        `Witness saw suspect with striking ${criminal.hair.toUpperCase()} HAIR.`,
        `Suspect sped off in a sleek ${criminal.vehicle.toUpperCase()}.`,
        `Witness heard them talking about playing ${criminal.hobby.toUpperCase()}.`,
        `Remarkable trait: suspect had a ${criminal.feature.toUpperCase()}!`
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
    this.renderer.drawCitySkyline(city.skyline);
    this.updateTimeDisplay();

    // Check if player arrived in final city
    if (this.currentCityId === this.currentCase.finalCity) {
      this.audio.suspenseEncounter();
      this.setDialog(`You are in ${city.name}! The suspect is near! Check your warrant before closing in!`);
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
    this.renderSubscreen("INVESTIGATE LOCATIONS", this.subscreenOptions);
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

    const items = [
      { title: warrantTitle },
      ...this.cluesGathered.map((c) => ({ title: `> ${c}` }))
    ];

    if (this.cluesGathered.length === 0) {
      items.push({ title: "No clues gathered yet. Question witnesses in town!" });
    }

    this.renderSubscreen("CASE DOSSIER [L]", items);
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
    if (this.subscreenMode === "investigate") {
      const placeOpt = this.subscreenOptions[this.subscreenIndex];
      this.closeSubscreen();

      // Draw witness portrait
      this.renderer.drawWitnessPortrait(placeOpt.data.witness);

      // Spend 2 hours
      if (!this.spendHours(2)) return;

      let clueText = "";
      if (this.currentCase.trail.includes(this.currentCityId)) {
        const cityClues = this.currentCase.clues[this.currentCityId];
        clueText = cityClues[placeOpt.index % cityClues.length];
      } else {
        const deadEnds = [
          `"Nobody matching that description was seen here! You've lost the trail!"`,
          `"Never heard of them. Maybe check other international transit hubs?"`,
          `"A dead end, detective! No suspicious sightings reported in this city."`
        ];
        clueText = deadEnds[placeOpt.index % deadEnds.length];
      }

      this.audio.clueFound();
      const fullClue = `${placeOpt.data.witness}: ${clueText}`;
      this.cluesGathered.push(`[${CITIES_DATA[this.currentCityId].name}] ${clueText}`);
      this.typewrite(fullClue, () => {
        this.setDialog(fullClue);
      });

      // If at final city and investigating, check for arrest
      if (this.currentCityId === this.currentCase.finalCity && placeOpt.index === 0) {
        setTimeout(() => this.attemptArrest(), 1800);
      }
    } else if (this.subscreenMode === "depart") {
      const flightOpt = this.subscreenOptions[this.subscreenIndex];
      this.closeSubscreen();

      this.audio.travel();
      if (!this.spendHours(4)) return;

      this.currentCityId = flightOpt.cityId;
      this.audio.confirm();
      this.enterCityHub();
      this.setDialog(`Arrived in ${CITIES_DATA[this.currentCityId].name}! Time to search for leads.`);
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
    } else if (this.subscreenMode === "dossier") {
      this.closeSubscreen();
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

    if (this.warrantSuspect && this.warrantSuspect.id === criminal.id) {
      this.audio.victory();
      this.renderer.drawVictoryScene(criminal);

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
    }
  }

  handleCancel() {
    this.audio.init();
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
      if (dir === "up") this.menuIndex = (this.menuIndex + 2) % 4;
      else if (dir === "down") this.menuIndex = (this.menuIndex + 2) % 4;
      else if (dir === "left") this.menuIndex = (this.menuIndex - 1 + 4) % 4;
      else if (dir === "right") this.menuIndex = (this.menuIndex + 1) % 4;
      this.audio.cursor();
      this.updateMenuHighlight();
    }
  }

  handleSelect() {
    this.audio.init();
    if (!this.subscreenMode && this.state === "CITY_HUB") {
      this.menuIndex = (this.menuIndex + 1) % 4;
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
    if (dialogBox) dialogBox.textContent = text;
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
