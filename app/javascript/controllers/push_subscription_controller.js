import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "push_subscription_id"

export default class extends Controller {
  static targets = ["button"]
  static values = { vapidPublicKey: String }

  async connect() {
    if (!("PushManager" in window) || !("Notification" in window)) return

    this.buttonTarget.classList.remove("hidden")
    await this.updateButtonLabel()
  }

  async toggle() {
    if (Notification.permission === "denied") {
      alert("Notifications are blocked. Please enable them in your browser settings.")
      return
    }

    const existing = await this.getSubscription()

    if (existing) {
      await this.unsubscribe(existing)
    } else {
      await this.subscribe()
    }

    await this.updateButtonLabel()
  }

  async subscribe() {
    const permission = await Notification.requestPermission()
    if (permission !== "granted") return

    const registration = await navigator.serviceWorker.ready
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
    })

    const { endpoint, keys: { p256dh, auth } } = subscription.toJSON()

    const response = await fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content
      },
      body: JSON.stringify({ endpoint, p256dh, auth })
    })

    if (response.ok) {
      const { id } = await response.json()
      localStorage.setItem(STORAGE_KEY, id)
    } else {
      await subscription.unsubscribe()
    }
  }

  async unsubscribe(subscription) {
    await subscription.unsubscribe()

    const id = localStorage.getItem(STORAGE_KEY)
    if (id) {
      await fetch(`/push_subscriptions/${id}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": document.querySelector("meta[name=csrf-token]").content }
      })
      localStorage.removeItem(STORAGE_KEY)
    }
  }

  async getSubscription() {
    const registration = await navigator.serviceWorker.ready
    return registration.pushManager.getSubscription()
  }

  async updateButtonLabel() {
    const subscription = await this.getSubscription()
    this.buttonTarget.textContent = subscription ? "Notifications On" : "Enable Notifications"
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = atob(base64)
    return Uint8Array.from([ ...rawData ].map((char) => char.charCodeAt(0)))
  }
}
