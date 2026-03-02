import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "menuButton", "backdrop"]

  connect() {
    this._handleKeydown = this._handleKeydown.bind(this)
  }

  disconnect() {
    document.removeEventListener("keydown", this._handleKeydown)
    document.body.style.overflow = ""
  }

  open() {
    this.menuTarget.removeAttribute("hidden")
    if (this.hasBackdropTarget) this.backdropTarget.removeAttribute("hidden")
    this.menuButtonTarget.setAttribute("aria-expanded", "true")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this._handleKeydown)
    this._setFirstFocus()
  }

  close() {
    this.menuTarget.setAttribute("hidden", "")
    if (this.hasBackdropTarget) this.backdropTarget.setAttribute("hidden", "")
    this.menuButtonTarget.setAttribute("aria-expanded", "false")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this._handleKeydown)
    this.menuButtonTarget.focus()
  }

  _handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      return
    }
    if (event.key === "Tab") {
      this._trapFocus(event)
    }
  }

  _setFirstFocus() {
    const focusable = this._focusableElements()
    if (focusable.length > 0) focusable[0].focus()
  }

  _trapFocus(event) {
    const focusable = this._focusableElements()
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]

    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  _focusableElements() {
    return Array.from(
      this.menuTarget.querySelectorAll(
        'a[href], button:not([disabled]), [tabindex]:not([tabindex="-1"])'
      )
    )
  }
}
