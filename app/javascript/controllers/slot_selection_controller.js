import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values  = { rateCents: Number }
  static targets = [ "slot", "summary", "checkoutButton", "slotIdsInput" ]

  connect() {
    this.selectedIds  = []
    this.anchorSlotId = null
    this.updateUI()
  }

  selectSlot(event) {
    const button = event.currentTarget
    const slotId = parseInt(button.dataset.slotId)

    const existingIndex = this.selectedIds.indexOf(slotId)

    if (existingIndex !== -1) {
      // Clicking an already-selected slot: deselect it and everything after
      this.selectedIds = this.selectedIds.slice(0, existingIndex)
      if (this.selectedIds.length === 0) this.anchorSlotId = null
    } else if (this.selectedIds.length === 0) {
      // First click: set anchor
      this.anchorSlotId = slotId
      this.selectedIds  = [ slotId ]
    } else {
      // Second (or later) click: try to fill range from anchor to this slot
      const range = this.consecutiveRange(this.anchorSlotId, slotId)
      if (range) {
        this.selectedIds = range
      } else {
        // Gap or backwards click: restart selection from this slot
        this.anchorSlotId = slotId
        this.selectedIds  = [ slotId ]
      }
    }

    this.updateUI()
  }

  // Returns an ordered array of slot IDs from fromId up to toId if all slots
  // in that span are consecutive (each endsAtMs === next startsAtMs).
  // Returns null if the range is invalid or non-consecutive.
  consecutiveRange(fromId, toId) {
    const sorted = this.slotTargets.slice().sort(
      (a, b) => parseInt(a.dataset.startsAtMs) - parseInt(b.dataset.startsAtMs)
    )

    const fromIndex = sorted.findIndex(el => parseInt(el.dataset.slotId) === fromId)
    const toIndex   = sorted.findIndex(el => parseInt(el.dataset.slotId) === toId)

    if (fromIndex === -1 || toIndex === -1 || toIndex <= fromIndex) return null

    const span = sorted.slice(fromIndex, toIndex + 1)

    // Every slot must end exactly when the next one starts
    for (let i = 0; i < span.length - 1; i++) {
      if (parseInt(span[i].dataset.endsAtMs) !== parseInt(span[i + 1].dataset.startsAtMs)) {
        return null
      }
    }

    return span.map(el => parseInt(el.dataset.slotId))
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
