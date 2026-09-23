import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "button", "status"]

  locate() {
    if (this.buttonTarget.disabled) return
    if (!window.isSecureContext || !navigator.geolocation) {
      this.statusTarget.textContent = "Location is unavailable. Enter the venue coordinates manually."
      return
    }
    this.buttonTarget.disabled = true
    this.statusTarget.textContent = "Finding your location…"
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        if (!this.element.isConnected) return
        this.latitudeTarget.value = coords.latitude.toFixed(6)
        this.longitudeTarget.value = coords.longitude.toFixed(6)
        this.buttonTarget.disabled = false
        this.statusTarget.textContent = "Location filled in. Save the event to apply it."
      },
      () => {
        if (!this.element.isConnected) return
        this.buttonTarget.disabled = false
        this.statusTarget.textContent = "Couldn't get your location. Allow location access and retry, or enter coordinates manually."
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
    )
  }
}
