import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["latitude", "longitude", "button", "status"]

  submit(event) {
    event.preventDefault()
    if (this.buttonTarget.disabled) return
    if (!window.isSecureContext || !navigator.geolocation) {
      this.statusTarget.textContent = "Location is unavailable. Open this page over HTTPS (or localhost for development)."
      return
    }
    this.buttonTarget.disabled = true
    this.statusTarget.textContent = "Finding your location…"
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => {
        if (!this.element.isConnected) return
        this.latitudeTarget.value = coords.latitude
        this.longitudeTarget.value = coords.longitude
        this.statusTarget.textContent = "Checking you in…"
        HTMLFormElement.prototype.submit.call(this.element)
      },
      (error) => {
        if (!this.element.isConnected) return
        this.buttonTarget.disabled = false
        this.statusTarget.textContent = error.code === 1
          ? "Location permission was denied. Allow location access in your browser, then try again."
          : "Couldn't find your location. Move somewhere with a better signal and try again."
      },
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 0 }
    )
  }
}
