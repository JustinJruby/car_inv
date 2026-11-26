import { Controller } from "@hotwired/stimulus"
import { readFavorites, markSeen } from "controllers/favorites_store"

// Favorites page. With no ids in the URL, load the saved ids from this browser and
// reload with them. With ids, show a "Price dropped" badge for any saved car whose
// price was reduced after the customer last opened favorites (FR-016).
export default class extends Controller {
  static targets = ["badge"]

  connect() {
    const params = new URLSearchParams(window.location.search)
    if (!params.has("ids")) {
      const ids = Object.keys(readFavorites())
      if (ids.length > 0) window.location.replace(`/favorites?ids=${ids.join(",")}`)
      return
    }

    const favorites = readFavorites()
    const seenIds = []
    this.badgeTargets.forEach((badge) => {
      const row = badge.closest("[data-car-id]")
      const carId = row.dataset.carId
      const favorite = favorites[carId]
      const droppedAt = row.dataset.priceDroppedAt
      if (favorite && droppedAt && new Date(droppedAt) > new Date(favorite.last_seen_at)) {
        badge.hidden = false
      }
      seenIds.push(carId)
    })
    markSeen(seenIds)
  }
}
