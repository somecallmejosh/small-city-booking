import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values  = { rateCents: Number }
  static targets = [ "slot", "summary", "checkoutButton", "slotIdsInput" ]

  connect() {
    this.selectedIds = []
    this.updateUI()
  }

  selectSlot(event) {
    const button     = event.currentTarget
    const slotId     = parseInt(button.dataset.slotId)
    const startsAtMs = parseInt(button.dataset.startsAtMs)
    const endsAtMs   = parseInt(button.dataset.endsAtMs)

    const existingIndex = this.selectedIds.indexOf(slotId)

    if (existingIndex !== -1) {
      // Deselect: keep only slots before this one (consecutive run breaks here)
      this.selectedIds = this.selectedIds.slice(0, existingIndex)
    } else if (this.selectedIds.length === 0) {
      this.selectedIds = [ slotId ]
    } else {
      // Check if this slot is consecutive with the last selected slot
      const lastSlotButton = this.slotTargets.find(
        el => parseInt(el.dataset.slotId) === this.selectedIds[this.selectedIds.length - 1]
      )
      const lastEndsAtMs = lastSlotButton ? parseInt(lastSlotButton.dataset.endsAtMs) : null

      if (lastEndsAtMs === startsAtMs) {
        this.selectedIds = [ ...this.selectedIds, slotId ]
      } else {
        // Non-consecutive: restart selection from this slot
        this.selectedIds = [ slotId ]
      }
    }

    this.updateUI()
  }

  submit(event) {
    event.preventDefault()

    const form = event.currentTarget.closest("form") || this.element.querySelector("form")

    // Remove old hidden inputs
    form.querySelectorAll("input[name='slot_ids[]']").forEach(el => el.remove())

    // Build new hidden inputs
    this.selectedIds.forEach(id => {
      const input = document.createElement("input")
      input.type  = "hidden"
      input.name  = "slot_ids[]"
      input.value = id
      form.appendChild(input)
    })

    form.submit()
  }

  updateUI() {
    const count      = this.selectedIds.length
    const totalCents = count * this.rateCentsValue
    const dollars    = (totalCents / 100).toFixed(2)

    // Update slot button states
    this.slotTargets.forEach(button => {
      const slotId = parseInt(button.dataset.slotId)
      if (this.selectedIds.includes(slotId)) {
        button.classList.add("ring-2", "ring-stone-900", "bg-stone-900", "text-white")
        button.classList.remove("bg-green-50", "text-green-800")
      } else {
        button.classList.remove("ring-2", "ring-stone-900", "bg-stone-900", "text-white")
        button.classList.add("bg-green-50", "text-green-800")
      }
    })

    // Update summary
    if (this.hasSummaryTarget) {
      if (count === 0) {
        this.summaryTarget.textContent = "Select slots to book"
      } else {
        this.summaryTarget.textContent = `${count} hour${count === 1 ? "" : "s"} — $${dollars}`
      }
    }

    // Enable/disable checkout button
    if (this.hasCheckoutButtonTarget) {
      this.checkoutButtonTarget.disabled = count === 0
    }
  }
}
