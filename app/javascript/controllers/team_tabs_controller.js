import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "section"]
  static values  = { active: String }

  connect() {
    this.show(this.activeValue || "all")
  }

  switch(event) {
    const team = event.currentTarget.dataset.team
    this.show(team)
  }

  show(team) {
    this.activeValue = team

    this.tabTargets.forEach(tab => {
      const isActive = tab.dataset.team === team
      tab.className = isActive ? this.activeClass() : this.inactiveClass()
    })

    this.sectionTargets.forEach(section => {
      section.hidden = team !== "all" && section.dataset.team !== team
    })
  }

  activeClass()   { return "px-4 py-2 text-sm font-medium rounded-lg bg-accent text-white transition-colors" }
  inactiveClass() { return "px-4 py-2 text-sm font-medium rounded-lg text-dim hover:text-ink hover:bg-elevated transition-colors" }
}
