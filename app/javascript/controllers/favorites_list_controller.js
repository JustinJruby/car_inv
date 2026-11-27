import { Controller } from "@hotwired/stimulus"
import { lastSeenFor, markSeen } from "controllers/favorites_store"

// Favorites page. The saved cars come from the server. A "Price dropped" badge shows for each car
// whose price was reduced after the customer last looked at favorites (FR-016). The baseline is
// when the car was last seen on this device, or when it was saved (spec 006, T013).
export default class extends Controller {
  connect() {
    const rows = this.element.querySelectorAll("[data-car-id]")
    rows.forEach((row) => {
      const carId = row.dataset.carId
      const droppedAt = row.dataset.priceDroppedAt
      const baseline = lastSeenFor(carId) || row.dataset.savedAt
      const badge = row.querySelector('[data-favorites-list-target="badge"]')
      if (badge && droppedAt && new Date(droppedAt) > new Date(baseline)) {
        badge.hidden = false
      }
    })
    markSeen(Array.from(rows, (row) => row.dataset.carId))
  }
}
