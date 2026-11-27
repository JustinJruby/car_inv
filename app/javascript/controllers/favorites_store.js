// Browser storage keeps one thing: when each saved car was last seen on the favorites page
// (spec 001, US6). It drives the "Price dropped" badge. Favorites themselves live on the server
// (spec 006, research R3). Every storage call is wrapped, so blocked or full storage degrades
// to no badge instead of an error.
const KEY = "car-inventory.last-seen"

function readSeen() {
  try {
    return JSON.parse(window.localStorage.getItem(KEY)) || {}
  } catch (_error) {
    return {}
  }
}

function writeSeen(seen) {
  try {
    window.localStorage.setItem(KEY, JSON.stringify(seen))
  } catch (_error) {
    // Storage unavailable: the badge baseline simply isn't remembered.
  }
}

export function lastSeenFor(carId) {
  return readSeen()[String(carId)] || null
}

export function markSeen(carIds) {
  const seen = readSeen()
  const now = new Date().toISOString()
  carIds.forEach((carId) => {
    seen[String(carId)] = now
  })
  writeSeen(seen)
}
