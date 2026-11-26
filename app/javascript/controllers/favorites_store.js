// Favorites live only in this browser (FR-014, FR-015). Every storage call is wrapped
// so a blocked or full localStorage degrades to "no favorites" instead of an error.
const KEY = "car-inventory.favorites"

export function readFavorites() {
  try {
    return JSON.parse(window.localStorage.getItem(KEY)) || {}
  } catch (_error) {
    return {}
  }
}

function writeFavorites(favorites) {
  try {
    window.localStorage.setItem(KEY, JSON.stringify(favorites))
  } catch (_error) {
    // Storage unavailable: the favorite simply isn't remembered.
  }
}

export function isFavorite(carId) {
  return Object.prototype.hasOwnProperty.call(readFavorites(), String(carId))
}

export function saveFavorite(carId) {
  const favorites = readFavorites()
  const now = new Date().toISOString()
  favorites[String(carId)] = favorites[String(carId)] || { saved_at: now, last_seen_at: now }
  writeFavorites(favorites)
}

export function removeFavorite(carId) {
  const favorites = readFavorites()
  delete favorites[String(carId)]
  writeFavorites(favorites)
}

export function markSeen(carIds) {
  const favorites = readFavorites()
  const now = new Date().toISOString()
  carIds.forEach((carId) => {
    if (favorites[String(carId)]) favorites[String(carId)].last_seen_at = now
  })
  writeFavorites(favorites)
}
