import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "actionBar", "counter"]

  toggle() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    const total   = this.checkboxTargets.length

    this.counterTarget.textContent = checked.length
    this.actionBarTarget.classList.toggle("hidden", checked.length === 0)
    this.actionBarTarget.classList.toggle("flex", checked.length > 0)

    this.selectAllTarget.checked       = checked.length === total && total > 0
    this.selectAllTarget.indeterminate = checked.length > 0 && checked.length < total
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => { cb.checked = checked })
    this.toggle()
  }
}
