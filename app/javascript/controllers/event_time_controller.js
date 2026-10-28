import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["startsAt", "endsAt"]

  connect() {
    this.updateEndTime()
  }

  updateEndTime() {
    const startValue = this.startsAtTarget.value
    if (!startValue) return

    this.endsAtTarget.min = startValue

    if (this.endsAtTarget.value && this.endsAtTarget.value <= startValue) {
      this.endsAtTarget.value = ""
    }
  }
}