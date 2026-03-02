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
    const menu = this.menuTarget
    const backdrop = this.hasBackdropTarget ? this.backdropTarget : null

    // Set "from" state before revealing, so the browser has something to transition from
    menu.classList.add("translate-x-full")
    if (backdrop) backdrop.classList.add("opacity-0")

    menu.removeAttribute("hidden")
    if (backdrop) backdrop.removeAttribute("hidden")

    // Force reflow so the browser registers the starting state before transitioning
    menu.offsetHeight

    // Animate to resting state
    menu.classList.remove("translate-x-full")
    if (backdrop) backdrop.classList.remove("opacity-0")

    this.menuButtonTarget.setAttribute("aria-expanded", "true")
    document.body.style.overflow = "hidden"
    document.addEventListener("keydown", this._handleKeydown)
    this._setFirstFocus()
  }

  close() {
    const menu = this.menuTarget
    const backdrop = this.hasBackdropTarget ? this.backdropTarget : null

    // Animate to "from" state
    menu.classList.add("translate-x-full")
    if (backdrop) backdrop.classList.add("opacity-0")

    this.menuButtonTarget.setAttribute("aria-expanded", "false")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this._handleKeydown)
    this.menuButtonTarget.focus()

    // Hide after the transition finishes (or immediately when motion is reduced)
    const hideAll = () => {
      menu.setAttribute("hidden", "")
      if (backdrop) backdrop.setAttribute("hidden", "")
    }

    const style = getComputedStyle(menu)
    const noTransition =
      style.transitionProperty === "none" ||
      parseFloat(style.transitionDuration) === 0

    if (noTransition) {
      hideAll()
    } else {
      menu.addEventListener("transitionend", hideAll, { once: true })
    }
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
