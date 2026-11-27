import { Controller } from "@hotwired/stimulus"
import { markSeen } from "controllers/favorites_store"

// Save/remove button on a car page. The saved state comes from the server (the page renders it),
// and each change is sent to the server (spec 006, T011).
export default class extends Controller {
  static values = { carId: Number, saved: Boolean }
  static targets = ["button"]

  connect() {
    this.render()
  }

  async toggle() {
    const response = await fetch(`/cars/${this.carIdValue}/favorite`, {
      method: this.savedValue ? "DELETE" : "POST",
      headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
      credentials: "same-origin"
    })
    if (!response.ok) return

    const body = await response.json()
    this.savedValue = body.saved
    if (body.saved) markSeen([this.carIdValue])
    this.render()
  }

  render() {
    this.buttonTarget.textContent = this.savedValue ? "Remove from favorites" : "Save to favorites"
  }
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}
