import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values  = { expiresAt: String }
  static targets = [ "display", "payButton", "expiredMessage" ]

  connect() {
    this.interval = setInterval(this.tick.bind(this), 1000)
    this.tick()
  }

  disconnect() {
    clearInterval(this.interval)
  }

  tick() {
    const remaining = new Date(this.expiresAtValue) - Date.now()

    if (remaining > 0) {
      const totalSeconds = Math.floor(remaining / 1000)
      const minutes      = Math.floor(totalSeconds / 60)
      const seconds      = totalSeconds % 60
      const formatted    = `${minutes}:${String(seconds).padStart(2, "0")}`

      if (this.hasDisplayTarget) {
        this.displayTarget.textContent = formatted
      }
    } else {
      clearInterval(this.interval)

      if (this.hasDisplayTarget) {
        this.displayTarget.textContent = "0:00"
      }
      if (this.hasPayButtonTarget) {
        this.payButtonTarget.disabled = true
      }
      if (this.hasExpiredMessageTarget) {
        this.expiredMessageTarget.classList.remove("hidden")
      }
    }
  }
}
