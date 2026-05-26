import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hint", "mergeForm", "toggleBtn"]

  togglePicking() {
    const opening = this.hintTarget.classList.contains("hidden")

    this.hintTarget.classList.toggle("hidden", !opening)
    this.mergeFormTargets.forEach(f => f.classList.toggle("hidden", !opening))

    if (opening) {
      this.toggleBtnTarget.textContent = "Cancel"
    } else {
      // Restore original label from data attribute
      this.toggleBtnTarget.textContent = this.toggleBtnTarget.dataset.label
    }
  }

  connect() {
    // Store original button label so we can restore it after cancel
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.dataset.label = this.toggleBtnTarget.textContent.trim()
    }
  }
}
