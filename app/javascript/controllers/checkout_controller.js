import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["payButton"]

  togglePay(event) {
    this.payButtonTarget.disabled = !event.target.checked
  }
}
