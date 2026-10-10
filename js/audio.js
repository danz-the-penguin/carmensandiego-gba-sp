/**
 * Where in the World is Carmen Sandiego? - Game Boy Advance (GBA) Edition
 * GBA Sound Engine (DirectSound + PSG Emulation via Web Audio API)
 * Features rich multi-voice polyphony, stereo panning, slap-bass, and crisp percussion.
 */

class GBASoundEngine {
  constructor() {
    this.ctx = null;
    this.masterGain = null;
    this.bgmGain = null;
    this.ambientGain = null;
    this.sfxGain = null;
    this.bgmEnabled = true;
    this.sfxEnabled = true;
    this.isPlayingBGM = false;
    this.bgmTimer = null;
    this.ambientTimer = null;
    this.currentStep = 0;
    this.currentRegion = "americas";
  }

  init() {
    if (this.ctx) {
      if (this.ctx.state === "suspended") {
        this.ctx.resume();
      }
      return;
    }

    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;

    this.ctx = new AudioContext();

    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.setValueAtTime(0.35, this.ctx.currentTime);
    this.masterGain.connect(this.ctx.destination);

    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.setValueAtTime(0.65, this.ctx.currentTime);
    this.sfxGain.connect(this.masterGain);

    this.bgmGain = this.ctx.createGain();
    this.bgmGain.gain.setValueAtTime(0.28, this.ctx.currentTime);
    this.bgmGain.connect(this.masterGain);

    this.ambientGain = this.ctx.createGain();
    this.ambientGain.gain.setValueAtTime(0.16, this.ctx.currentTime);
    this.ambientGain.connect(this.masterGain);
  }

  // --- Sound Effects ---

  playTone(freq, duration = 0.08, type = "square", volume = 0.5, pan = 0) {
    if (!this.sfxEnabled) return;
    this.init();
    if (!this.ctx) return;

    try {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = type;
      osc.frequency.setValueAtTime(freq, this.ctx.currentTime);

      gain.gain.setValueAtTime(volume, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);

      if (this.ctx.createStereoPanner) {
        const panner = this.ctx.createStereoPanner();
        panner.pan.setValueAtTime(pan, this.ctx.currentTime);
        osc.connect(gain);
        gain.connect(panner);
        panner.connect(this.sfxGain);
      } else {
        osc.connect(gain);
        gain.connect(this.sfxGain);
      }

      osc.start();
      osc.stop(this.ctx.currentTime + duration);
    } catch (e) {
      // Audio fallback
    }
  }

  textBlip() {
    if (!this.sfxEnabled) return;
    this.init();
    if (!this.ctx) return;
    // Crisp GBA dialog click
    this.playTone(880 + Math.random() * 120, 0.02, "triangle", 0.09);
  }

  cursor() {
    this.playTone(440, 0.04, "square", 0.15);
  }

  confirm() {
    this.init();
    this.playTone(523, 0.06, "square", 0.22);
    setTimeout(() => this.playTone(784, 0.08, "square", 0.22), 40);
  }

  cancel() {
    this.init();
    this.playTone(392, 0.05, "square", 0.2);
    setTimeout(() => this.playTone(261, 0.08, "square", 0.2), 45);
  }

  shoulderTrigger() {
    // Distinctive GBA L/R bumper click
    this.init();
    this.playTone(600, 0.03, "sine", 0.25);
    setTimeout(() => this.playTone(900, 0.04, "sine", 0.25), 25);
  }

  lightSwitch() {
    // Distinctive GBA SP small rubber brightness button click
    this.init();
    this.playTone(720, 0.02, "triangle", 0.2);
    setTimeout(() => this.playTone(1050, 0.03, "sine", 0.2), 20);
  }

  clueFound() {
    this.init();
    const notes = [440, 554, 659, 880];
    notes.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.1, "triangle", 0.3), idx * 75);
    });
  }

  travel() {
    this.init();
    if (!this.ctx || !this.sfxEnabled) return;

    // GBA Stereo jet / train transit sound
    const bufferSize = this.ctx.sampleRate * 0.5;
    const buffer = this.ctx.createBuffer(2, bufferSize, this.ctx.sampleRate);
    const left = buffer.getChannelData(0);
    const right = buffer.getChannelData(1);

    for (let i = 0; i < bufferSize; i++) {
      left[i] = (Math.random() * 2 - 1) * 0.18;
      right[i] = (Math.random() * 2 - 1) * 0.18;
    }

    const noise = this.ctx.createBufferSource();
    noise.buffer = buffer;

    const filter = this.ctx.createBiquadFilter();
    filter.type = "lowpass";
    filter.frequency.setValueAtTime(1200, this.ctx.currentTime);
    filter.frequency.exponentialRampToValueAtTime(100, this.ctx.currentTime + 0.5);

    const gain = this.ctx.createGain();
    gain.gain.setValueAtTime(0.35, this.ctx.currentTime);
    gain.gain.linearRampToValueAtTime(0.001, this.ctx.currentTime + 0.5);

    noise.connect(filter);
    filter.connect(gain);
    gain.connect(this.sfxGain);

    noise.start();
  }

  warrantIssued() {
    this.init();
    const fanfare = [523, 659, 784, 1046, 1318];
    fanfare.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.12, "square", 0.3), idx * 80);
    });
  }

  suspenseEncounter() {
    this.init();
    const notes = [220, 207, 196, 185];
    notes.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.16, "sawtooth", 0.35), idx * 90);
    });
  }

  victory() {
    this.init();
    const fan = [330, 392, 494, 659, 784, 988, 1318];
    fan.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.18, "square", 0.35), idx * 80);
    });
  }

  gameOver() {
    this.init();
    const notes = [370, 349, 329, 293, 246];
    notes.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.2, "sawtooth", 0.35), idx * 110);
    });
  }

  impact() {
    this.init();
    this.playTone(110, 0.35, "sawtooth", 0.55);
  }

  cuffs() {
    this.init();
    this.playTone(1600, 0.05, "triangle", 0.4);
    setTimeout(() => this.playTone(2100, 0.06, "square", 0.4), 60);
  }

  radioLock() {
    this.init();
    const tones = [880, 1320, 1760];
    tones.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.1, "sine", 0.35), idx * 75);
    });
  }

  ping() {
    this.init();
    this.playTone(1480, 0.08, "sine", 0.25);
  }

  whoosh() {
    this.init();
    this.playTone(280, 0.15, "triangle", 0.35);
  }

  siren() {
    this.init();
    const tones = [784, 988, 784, 988];
    tones.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.08, "sawtooth", 0.3), idx * 80);
    });
  }

  gadget() {
    this.init();
    const tones = [440, 660, 880, 1320];
    tones.forEach((freq, idx) => {
      setTimeout(() => this.playTone(freq, 0.06, "sine", 0.35), idx * 50);
    });
  }

  getRegionForCity(cityId) {
    const id = (cityId || "").toLowerCase();
    if (["london", "paris", "rome", "athens", "moscow", "reykjavik"].includes(id)) return "europe";
    if (["tokyo", "beijing", "kathmandu"].includes(id)) return "asia";
    if (["rio", "mexicocity"].includes(id)) return "latin";
    if (["cairo", "nairobi"].includes(id)) return "africa_mideast";
    return "americas";
  }

  // --- Dynamic Regional Musical Motifs ---

  startBGM(region = null) {
    if (region) this.currentRegion = region;
    if (!this.bgmEnabled) return;
    this.init();
    if (!this.ctx) return;

    if (this.isPlayingBGM && this.bgmTimer) {
      clearTimeout(this.bgmTimer);
      this.bgmTimer = null;
    }

    this.isPlayingBGM = true;
    this.currentStep = 0;

    let bass = [];
    let lead = [];
    let leadWave = "square";
    let stepMs = 155;

    switch (this.currentRegion) {
      case "europe":
        stepMs = 165;
        leadWave = "square";
        bass = [220.0, 0, 164.8, 0, 174.6, 0, 146.8, 0, 164.8, 0, 164.8, 0, 220.0, 0, 220.0, 0];
        lead = [440.0, 523.3, 659.3, 523.3, 493.9, 0, 415.3, 493.9, 440.0, 523.3, 659.3, 880.0, 659.3, 0, 523.3, 440.0];
        break;
      case "asia":
        stepMs = 145;
        leadWave = "square";
        bass = [220.0, 0, 220.0, 0, 146.8, 0, 146.8, 0, 164.8, 0, 164.8, 0, 220.0, 0, 220.0, 0];
        lead = [440.0, 523.3, 587.3, 659.3, 784.0, 659.3, 587.3, 523.3, 587.3, 659.3, 784.0, 880.0, 784.0, 659.3, 523.3, 440.0];
        break;
      case "latin":
        stepMs = 150;
        leadWave = "triangle";
        bass = [146.8, 0, 146.8, 220.0, 196.0, 0, 196.0, 146.8, 130.8, 0, 130.8, 196.0, 220.0, 0, 220.0, 146.8];
        lead = [349.2, 440.0, 523.3, 440.0, 392.0, 493.9, 587.3, 493.9, 329.6, 392.0, 523.3, 392.0, 277.2, 329.6, 440.0, 329.6];
        break;
      case "africa_mideast":
        stepMs = 155;
        leadWave = "sawtooth";
        bass = [146.8, 146.8, 155.6, 146.8, 196.0, 196.0, 185.0, 155.6, 146.8, 146.8, 155.6, 146.8, 220.0, 220.0, 185.0, 146.8];
        lead = [293.7, 311.1, 370.0, 392.0, 440.0, 392.0, 370.0, 311.1, 392.0, 440.0, 466.2, 440.0, 370.0, 392.0, 370.0, 311.1];
        break;
      default:
        stepMs = 155;
        leadWave = "triangle";
        bass = [146.8, 0, 146.8, 174.6, 196.0, 0, 174.6, 146.8, 130.8, 0, 130.8, 146.8, 174.6, 0, 164.8, 130.8];
        lead = [293.7, 0, 349.2, 392.0, 440.0, 0, 392.0, 349.2, 261.6, 0, 329.6, 349.2, 392.0, 440.0, 415.3, 293.7];
        break;
    }

    const tick = () => {
      if (!this.isPlayingBGM) return;

      const step = this.currentStep % 16;

      // Bass channel
      const bFreq = bass[step];
      if (bFreq > 0 && this.bgmEnabled) {
        this.playTone(bFreq, 0.14, "sawtooth", 0.18, -0.3);
      }

      // Lead melody
      const lFreq = lead[step];
      if (lFreq > 0 && this.bgmEnabled) {
        this.playTone(lFreq, 0.11, leadWave, 0.14, 0.3);
      }

      // Regional Percussion
      if (this.bgmEnabled) {
        if (this.currentRegion === "latin") {
          if (step % 4 === 0 || step % 4 === 3) this.playDrum(0.04, 0.08);
        } else if (this.currentRegion === "asia") {
          if (step % 8 === 4) this.playTone(880, 0.03, "square", 0.12);
        } else if (this.currentRegion === "africa_mideast") {
          if (step % 4 === 0 || step % 8 === 6) this.playDrum(0.06, 0.13);
        } else {
          if (step === 4 || step === 12) this.playDrum(0.06, 0.12);
        }
      }

      this.currentStep++;
      this.bgmTimer = setTimeout(tick, stepMs);
    };

    tick();
    this.startAmbientFoley(this.currentRegion);
  }

  stopBGM() {
    this.isPlayingBGM = false;
    if (this.bgmTimer) {
      clearTimeout(this.bgmTimer);
      this.bgmTimer = null;
    }
    this.stopAmbientFoley();
  }

  toggleBGM() {
    this.bgmEnabled = !this.bgmEnabled;
    if (this.bgmEnabled) {
      this.startBGM(this.currentRegion);
    } else {
      this.stopBGM();
    }
    return this.bgmEnabled;
  }

  // --- Ambient Environmental Foley ---

  startAmbientFoley(region) {
    if (!this.bgmEnabled) return;
    this.init();
    if (!this.ctx || !this.ambientGain) return;
    this.stopAmbientFoley();

    const playFoleyPulse = () => {
      if (!this.bgmEnabled || !this.ctx) return;
      try {
        switch (region) {
          case "europe":
            this.playTone(1800 + Math.random() * 400, 0.04, "sine", 0.04);
            break;
          case "asia":
            this.playTone(2400 + Math.random() * 600, 0.06, "triangle", 0.03);
            break;
          case "latin":
            this.playDrum(0.25, 0.06);
            break;
          case "africa_mideast":
            this.playDrum(0.20, 0.07);
            break;
          default:
            this.playTone(140 + Math.random() * 40, 0.25, "triangle", 0.04);
            break;
        }
      } catch (e) {}
      this.ambientTimer = setTimeout(playFoleyPulse, 2400 + Math.random() * 1800);
    };

    this.ambientTimer = setTimeout(playFoleyPulse, 1000);
  }

  stopAmbientFoley() {
    if (this.ambientTimer) {
      clearTimeout(this.ambientTimer);
      this.ambientTimer = null;
    }
  }

  playDrum(duration = 0.05, volume = 0.1) {
    if (!this.ctx || !this.bgmEnabled) return;
    try {
      const bufferSize = this.ctx.sampleRate * duration;
      const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
      const data = buffer.getChannelData(0);
      for (let i = 0; i < bufferSize; i++) {
        data[i] = (Math.random() * 2 - 1) * volume;
      }
      const noise = this.ctx.createBufferSource();
      noise.buffer = buffer;
      const gain = this.ctx.createGain();
      gain.gain.setValueAtTime(volume, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);
      noise.connect(gain);
      gain.connect(this.bgmGain);
      noise.start();
    } catch (e) {}
  }
}

const gbaAudio = new GBASoundEngine();

if (typeof window !== "undefined") {
  window.GBASoundEngine = GBASoundEngine;
  window.gbaAudio = gbaAudio;
}
if (typeof module !== "undefined" && module.exports) {
  module.exports = { GBASoundEngine, gbaAudio };
}
