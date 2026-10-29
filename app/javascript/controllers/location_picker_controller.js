import { Controller } from "@hotwired/stimulus"

let leafletLoad

// Officer-facing location picker: search -> pin on map -> drag/click to adjust,
// or choose from a saved list. Writes latitude/longitude into coordinate fields and
// a readable name into the visible location field. Leaflet is loaded globally (L).
export default class extends Controller {
  static targets = ["query", "results", "status", "map", "mapFrame", "mapError",
                    "fullscreenButton", "fullscreenStatus",
                    "latitude", "longitude", "name", "saved"]
  static values = {
    searchUrl: String,
    noResultsMessage: String,
    mapErrorMessage: String,
    searchErrorMessage: String,
    missingLocationMessage: String,
    missingNameMessage: String,
    defaultLat: { type: Number, default: 39.8283 },
    defaultLng: { type: Number, default: -98.5795 },
    defaultZoom: { type: Number, default: 4 },
    pinZoom: { type: Number, default: 17 }
  }

  async connect() {
    this.autoNamed = false
    this.timer = null
    const connection = this.connection = {}
    try {
      await this.loadLeaflet()
      if (this.connection === connection && this.element.isConnected) this.initMap()
    } catch (_) {
      if (this.connection === connection && this.element.isConnected) this.showMapError()
    }
  }

  disconnect() {
    this.connection = null
    if (this.fullscreen) this.exitFullscreen()
    clearTimeout(this.timer)
    this.searchAbort?.abort()
    this.reverseAbort?.abort()
    this.destroyMap()
  }

  // Share one asynchronous library request across Turbo visits. Never reload
  // the page to recover a map: the rest of the event form is an unsaved draft.
  loadLeaflet() {
    if (window.L) return Promise.resolve()
    if (leafletLoad) return leafletLoad

    leafletLoad = new Promise((resolve, reject) => {
      const script = document.createElement("script")
      script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
      script.crossOrigin = ""
      script.async = true
      const fail = () => {
        clearTimeout(timeout)
        script.remove()
        leafletLoad = null
        reject(new Error("The map could not be loaded"))
      }
      const timeout = setTimeout(fail, 10000)
      script.addEventListener("error", fail, { once: true })
      script.addEventListener("load", () => {
        clearTimeout(timeout)
        window.L ? resolve() : fail()
      }, { once: true })
      document.head.appendChild(script)
    })
    return leafletLoad
  }

  // ---- map ---------------------------------------------------------------

  initMap() {
    try {
      const L = window.L
      if (!L) throw new Error("Leaflet did not load")
      this.mapFrameTarget.hidden = false
      this.mapErrorTarget.hidden = true

      const lat = parseFloat(this.latitudeTarget.value)
      const lng = parseFloat(this.longitudeTarget.value)
      const hasPoint = Number.isFinite(lat) && Number.isFinite(lng)

      this.map = L.map(this.mapTarget).setView(
        hasPoint ? [lat, lng] : [this.defaultLatValue, this.defaultLngValue],
        hasPoint ? this.pinZoomValue : this.defaultZoomValue
      )

      let loaded = 0
      let failed = 0
      const tiles = L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
        maxZoom: 19,
        attribution: "&copy; OpenStreetMap contributors"
      }).addTo(this.map)
      tiles.on("tileload", () => { loaded += 1 })
      tiles.on("tileerror", () => {
        failed += 1
        if (loaded === 0 && failed >= 3) this.showMapError()
      })

      this.map.on("click", (event) => {
        const { lat, lng } = event.latlng.wrap()
        this.setPoint(lat, lng, { reverse: true })
      })

      if (hasPoint) this.placeMarker(lat, lng)
    } catch (error) {
      this.showMapError()
    }
  }

  destroyMap() {
    try { this.map?.remove() } catch (_) { /* already gone */ }
    this.map = null
    this.marker = null
  }

  // ---- full screen -------------------------------------------------------

  toggleFullscreen() {
    this.fullscreen ? this.exitFullscreen() : this.enterFullscreen()
  }

  enterFullscreen() {
    if (!this.map) return
    this.fullscreen = true
    Object.assign(this.mapFrameTarget.style, {
      position: "fixed", top: "0", right: "0", bottom: "0", left: "0",
      zIndex: "10000", background: "#fff"
    })
    this.mapTarget.style.height = "100%"
    this.fullscreenButtonTarget.textContent = "Done"
    this.fullscreenButtonTarget.setAttribute("aria-pressed", "true")
    this.fullscreenStatusTarget.hidden = false
    this.fullscreenStatusTarget.textContent = this.statusTarget.textContent ||
      "Click the map to drop a pin, or drag the pin. Press Done when finished."
    this.previousOverflow = document.body.style.overflow
    document.body.style.overflow = "hidden"
    this.onEscape = (event) => { if (event.key === "Escape") this.exitFullscreen() }
    document.addEventListener("keydown", this.onEscape)
    this.refreshMapSize()
  }

  exitFullscreen() {
    this.fullscreen = false
    this.mapFrameTarget.removeAttribute("style")
    this.mapFrameTarget.style.position = "relative"
    this.mapTarget.style.height = "320px"
    this.fullscreenButtonTarget.textContent = "Full screen"
    this.fullscreenButtonTarget.setAttribute("aria-pressed", "false")
    this.fullscreenStatusTarget.hidden = true
    document.body.style.overflow = this.previousOverflow || ""
    document.removeEventListener("keydown", this.onEscape)
    this.refreshMapSize()
  }

  refreshMapSize() {
    // Leaflet must be told when its container changes size.
    requestAnimationFrame(() => {
      this.map?.invalidateSize()
      if (this.marker) this.map?.panTo(this.marker.getLatLng())
    })
  }

  showMapError() {
    if (this.fullscreen) this.exitFullscreen()
    this.destroyMap()
    this.mapFrameTarget.hidden = true
    this.mapErrorTarget.textContent = this.mapErrorMessageValue
    this.mapErrorTarget.hidden = false
  }

  placeMarker(lat, lng) {
    if (!this.map) return
    if (this.marker) {
      this.marker.setLatLng([lat, lng])
      return
    }
    this.marker = window.L.marker([lat, lng], {
      draggable: true,
      keyboard: true,
      title: "Event location (drag to adjust)"
    }).addTo(this.map)
    this.marker.on("dragend", () => {
      const { lat, lng } = this.marker.getLatLng().wrap()
      this.setPoint(lat, lng, { reverse: true })
    })
  }

  // ---- choosing a point --------------------------------------------------

  setPoint(lat, lng, { label = null, reverse = false, recenter = false } = {}) {
    this.latitudeTarget.value = lat.toFixed(6)
    this.longitudeTarget.value = lng.toFixed(6)
    this.placeMarker(lat, lng)
    if (recenter && this.map) this.map.setView([lat, lng], this.pinZoomValue)

    if (label) {
      this.nameTarget.value = label
      this.autoNamed = true
      this.setStatus("Location selected. Drag the pin to fine-tune it.")
    } else if (reverse && (this.nameTarget.value.trim() === "" || this.autoNamed)) {
      this.reverseLookup(lat, lng)
    } else {
      this.setStatus("Pin moved. The location name was left as you typed it.")
    }
  }

  chooseSaved() {
    if (!this.hasSavedTarget) return
    const option = this.savedTarget.selectedOptions[0]
    if (!option || !option.value) return
    this.clearResults()
    this.setPoint(parseFloat(option.dataset.latitude), parseFloat(option.dataset.longitude), {
      label: option.dataset.name,
      recenter: true
    })
  }

  useMyLocation() {
    if (!navigator.geolocation) {
      this.setStatus("Your browser can't share its location. Enter coordinates manually, search, or choose from the list.", { error: true })
      return
    }
    this.setStatus("Finding your location…")
    navigator.geolocation.getCurrentPosition(
      (position) => {
        if (!this.element.isConnected) return
        this.setPoint(position.coords.latitude, position.coords.longitude, { reverse: true, recenter: true })
      },
      () => {
        if (!this.element.isConnected) return
        this.setStatus("Couldn't get your location. Your event details are still here. Enter coordinates manually, search, or choose from the list.", { error: true })
      },
      { enableHighAccuracy: true, timeout: 10000 }
    )
  }

  nameEdited() {
    this.autoNamed = false
  }

  coordinatesEdited() {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)
    if (Number.isFinite(lat) && Math.abs(lat) <= 90 && Number.isFinite(lng) && Math.abs(lng) <= 180) {
      this.placeMarker(lat, lng)
      if (this.map) this.map.setView([lat, lng], this.pinZoomValue)
    }
  }

  // ---- search ------------------------------------------------------------

  queryKeydown(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.search()
    }
  }

  queueSearch() {
    clearTimeout(this.timer)
    if (this.queryTarget.value.trim().length < 3) {
      this.clearResults()
      return
    }
    this.timer = setTimeout(() => this.search(), 700)
  }

  async search(event) {
    event?.preventDefault()
    clearTimeout(this.timer)
    const query = this.queryTarget.value.trim()
    if (query.length < 3) {
      this.setStatus("Type at least 3 characters to search.", { error: true })
      return
    }

    this.searchAbort?.abort()
    this.searchAbort = new AbortController()
    this.setStatus("Searching…")

    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("q", query)
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.searchAbort.signal
      })
      const data = await response.json().catch(() => ({}))
      if (!response.ok) throw new Error(data.error || this.searchErrorMessageValue)

      if (!data.results || data.results.length === 0) {
        this.clearResults()
        this.setStatus(this.noResultsMessageValue, { error: true })
        return
      }
      this.renderResults(data.results)
      this.setStatus(`${data.results.length} match${data.results.length === 1 ? "" : "es"} found. Pick one to place the pin.`)
    } catch (error) {
      if (error.name === "AbortError") return
      this.clearResults()
      this.setStatus(error.message || this.searchErrorMessageValue, { error: true })
    }
  }

  async reverseLookup(lat, lng) {
    this.reverseAbort?.abort()
    this.reverseAbort = new AbortController()
    this.setStatus("Pin placed. Looking up its address…")
    try {
      const url = new URL(this.searchUrlValue, window.location.origin)
      url.searchParams.set("lat", lat)
      url.searchParams.set("lng", lng)
      const response = await fetch(url, {
        headers: { Accept: "application/json" },
        signal: this.reverseAbort.signal
      })
      const data = await response.json().catch(() => ({}))
      const match = response.ok ? data.results?.[0] : null
      if (match) {
        this.nameTarget.value = match.label
        this.autoNamed = true
        this.setStatus("Pin placed. Edit the name below if you'd like something friendlier.")
      } else {
        this.setStatus("Pin placed, but no address was found. Type a name for this spot below.", { error: true })
      }
    } catch (error) {
      if (error.name === "AbortError") return
      this.setStatus("Pin placed, but the address lookup failed. Type a name for this spot below.", { error: true })
    }
  }

  renderResults(results) {
    const items = results.map((result) => {
      const item = document.createElement("li")
      const button = document.createElement("button")
      button.type = "button"
      button.setAttribute("role", "option")
      button.textContent = result.label // textContent: never inject provider text as HTML
      button.addEventListener("click", () => {
        this.clearResults()
        this.setPoint(result.latitude, result.longitude, { label: result.label, recenter: true })
      })
      item.appendChild(button)
      return item
    })
    this.resultsTarget.replaceChildren(...items)
  }

  clearResults() {
    this.resultsTarget.replaceChildren()
  }

  // ---- submit guard ------------------------------------------------------

  validate(event) {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)
    const noPoint = this.latitudeTarget.value.trim() === "" && this.longitudeTarget.value.trim() === ""
    const pointOk = Number.isFinite(lat) && Math.abs(lat) <= 90 &&
                    Number.isFinite(lng) && Math.abs(lng) <= 180

    if ((!noPoint && !pointOk) || this.nameTarget.value.trim() === "") {
      event.preventDefault()
      const missingName = this.nameTarget.value.trim() === ""
      this.setStatus(missingName ? this.missingNameMessageValue : this.missingLocationMessageValue, { error: true })
      ;(missingName ? this.nameTarget : this.latitudeTarget).focus()
    }
  }

  setStatus(message, { error = false } = {}) {
    this.statusTarget.textContent = message
    this.statusTarget.dataset.state = error ? "error" : "info"
    this.statusTarget.style.color = error ? "#b00020" : ""
    if (this.fullscreen) {
      this.fullscreenStatusTarget.textContent = message
      this.fullscreenStatusTarget.style.color = error ? "#b00020" : ""
    }
  }
}
