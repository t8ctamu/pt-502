import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["consent", "phoneFields", "phoneInput", "errors"]

  connect() {
    this.togglePhone()
    if (this.hasErrorsTarget) this.errorsTarget.focus()
  }

  togglePhone() {
    if (!this.hasConsentTarget) return

    const sharing = this.consentTarget.checked
    this.phoneFieldsTarget.hidden = !sharing
    this.phoneInputTarget.disabled = !sharing
    this.phoneInputTarget.required = sharing
  }
}
