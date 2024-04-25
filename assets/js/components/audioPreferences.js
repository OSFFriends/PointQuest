import AudioManager from "../audioManager"

export default class AudioPreferences extends HTMLElement {
  constructor() {
    super()

    this.audioManager = new AudioManager()
  }

  connectedCallback() {
    const style = document.createElement("link")
    style.setAttribute("rel", "stylesheet")
    // pull in global css styling
    style.setAttribute("href", "/assets/app.css")

    const shadow = this.attachShadow( { mode: "open" })

    this.button = document.createElement("button")
    this.button.setAttribute("class", "flex items-center gap-x-2")
    this.icon = document.createElement("span")
    this.icon.setAttribute("class", this.getIcon())

    const text = document.createElement("span")
    text.textContent = "Audio"

    this.button.appendChild(this.icon)
    this.button.appendChild(text)
    shadow.append(style)
    shadow.appendChild(this.button)

    // set up handlers
    this.button.addEventListener("click", event => {
      this.audioManager.toggleAudio()

      this.icon.setAttribute("class", this.getIcon())
    })
  }

  getIcon() {
    return this.audioManager.checkEnabled() ? "hero-speaker-wave" : "hero-speaker-x-mark"
  }
}

customElements.define("audio-preferences", AudioPreferences)
