import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["visible", "hidden", "btnHours", "btnMinutes", "hint"]

  connect() {
    this.mode = "hours"
    this.visibleTarget.value = parseFloat(this.hiddenTarget.value || 0).toFixed(2)
    this.updateVisibleOnChange()
  }

  switchHours() {
    if (this.mode === "hours") return
    const minutes = parseFloat(this.visibleTarget.value) || 0
    const hours = (minutes / 60).toFixed(2)
    this.visibleTarget.value = hours
    this.hiddenTarget.value = hours
    this.mode = "hours"
    this.updateUI()
  }

  switchMinutes() {
    if (this.mode === "minutes") return
    const hours = parseFloat(this.visibleTarget.value) || 0
    this.visibleTarget.value = Math.round(hours * 60)
    this.mode = "minutes"
    this.updateUI()
  }

  updateVisibleOnChange() {
    this.visibleTarget.addEventListener("input", () => {
      const val = parseFloat(this.visibleTarget.value) || 0
      if (this.mode === "hours") {
        this.hiddenTarget.value = val.toFixed(2)
      } else {
        this.hiddenTarget.value = (val / 60).toFixed(2)
      }
    })
  }

  updateUI() {
    const active   = "px-3 py-1.5 text-sm font-medium rounded-md bg-accent text-white"
    const inactive = "px-3 py-1.5 text-sm font-medium rounded-md text-dim hover:text-ink"

    if (this.mode === "hours") {
      this.btnHoursTarget.className   = active
      this.btnMinutesTarget.className = inactive
      this.hintTarget.textContent     = "e.g. 3.5 for 3 hours 30 min"
      this.visibleTarget.step         = "0.5"
    } else {
      this.btnMinutesTarget.className = active
      this.btnHoursTarget.className   = inactive
      this.hintTarget.textContent     = "e.g. 210 for 3 hours 30 min"
      this.visibleTarget.step         = "5"
    }
  }
}
