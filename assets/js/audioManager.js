let preferences

export default () => {
  const AUDIO_PREF_KEY = "audioPreferences"

  // Available sound effects
  const effects = {
    attack: new Audio("/audio/plastic-click.wav"),
    win: new Audio("/audio/win.wav")
  }

  // Seed localstorage with audio prefs if not already available
  if (localStorage.getItem(AUDIO_PREF_KEY) == null) {
    localStorage.setItem(AUDIO_PREF_KEY, true)
  }

  const toggleAudio = () => localStorage.setItem(AUDIO_PREF_KEY, !checkEnabled())

  const checkEnabled = () => localStorage.getItem(AUDIO_PREF_KEY) == "true"

  window.addEventListener("phx:play-sound", event => {
    if (checkEnabled()) {
      if (effects[event.detail.event]) {
        return effects[event.detail.event].play()
      }
    }
  })

  window.addEventListener("phx:toggle-audio", toggleAudio)

  return {
    toggleAudio,
    checkEnabled
  }
}
