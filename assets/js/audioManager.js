export default class AudioManager {
  static AUDIO_PREF_KEY = "audioPreferences";

  static effects = {
    alert: new Audio("/audio/alert.wav"),
    attack: new Audio("/audio/click.wav"),
    win: new Audio("/audio/win.wav"),
  };

  constructor({ storage = localStorage } = {}) {
    this.storage = storage;

    if (this.storage.getItem(AudioManager.AUDIO_PREF_KEY) == null) {
      this.storage.setItem(AudioManager.AUDIO_PREF_KEY, true);
    }

    window.addEventListener("phx:play-sound", (event) => {
      if (this.checkEnabled()) {
        if (AudioManager.effects[event.detail.event]) {
          return AudioManager.effects[event.detail.event].play();
        }
      }
    });
  }

  toggleAudio() {
    return this.storage.setItem(
      AudioManager.AUDIO_PREF_KEY,
      !this.checkEnabled(),
    );
  }

  checkEnabled() {
    return this.storage.getItem(AudioManager.AUDIO_PREF_KEY) == "true";
  }
}
