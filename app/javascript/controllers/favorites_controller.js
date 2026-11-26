import { Controller } from "@hotwired/stimulus"
import { isFavorite, saveFavorite, removeFavorite } from "controllers/favorites_store"

// Save/remove button on a car page.
export default class extends Controller {
  static values = { carId: Number }
  static targets = ["button"]

  connect() {
    this.render()
  }

  toggle() {
    if (isFavorite(this.carIdValue)) {
      removeFavorite(this.carIdValue)
    } else {
      saveFavorite(this.carIdValue)
    }
    this.render()
  }

  render() {
    this.buttonTarget.textContent = isFavorite(this.carIdValue) ? "Remove from favorites" : "Save to favorites"
  }
}
