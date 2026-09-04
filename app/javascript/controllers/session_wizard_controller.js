import { Controller } from "@hotwired/stimulus"

// Une étape à la fois pendant la session de 3h. L'index courant est persisté en
// localStorage (par semaine) pour survivre à un verrouillage d'écran.
export default class extends Controller {
  static targets = ["panel", "dot", "counter", "prev", "next"]
  static values = { storageKey: String, total: Number }

  connect() {
    this.index = this.load()
    this.render()
  }

  next() { this.go(this.index + 1) }
  prev() { this.go(this.index - 1) }

  go(i) {
    this.index = Math.max(0, Math.min(this.totalValue - 1, i))
    this.save()
    this.render()
  }

  render() {
    this.panelTargets.forEach((el, i) => { el.hidden = i !== this.index })
    this.dotTargets.forEach((el, i) => {
      el.classList.remove("bg-zest-400", "bg-chloro-400", "bg-chloro-900")
      el.classList.add(i === this.index ? "bg-zest-400" : i < this.index ? "bg-chloro-400" : "bg-chloro-900")
    })
    if (this.hasCounterTarget) this.counterTarget.textContent = `Étape ${this.index + 1} sur ${this.totalValue}`
    if (this.hasPrevTarget) this.prevTarget.disabled = this.index === 0
    if (this.hasNextTarget) {
      const last = this.index === this.totalValue - 1
      this.nextTarget.textContent = last ? "Session terminée" : "Étape terminée"
      this.nextTarget.disabled = last
    }
  }

  load() {
    try {
      const v = parseInt(localStorage.getItem(this.storageKeyValue), 10)
      return Number.isFinite(v) ? Math.max(0, Math.min(this.totalValue - 1, v)) : 0
    } catch { return 0 }
  }

  save() {
    try { localStorage.setItem(this.storageKeyValue, String(this.index)) } catch { /* quota/private mode */ }
  }
}
