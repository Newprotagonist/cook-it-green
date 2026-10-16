import { Controller } from "@hotwired/stimulus"

// Mode Cuisine : toutes les étapes sont visibles en frise, seule l'étape
// courante est dépliée. État (étapes faites + étape courante) persisté en
// localStorage par semaine, pour survivre à un verrouillage d'écran.
// L'ancien format (un entier brut, une seule étape affichée à la fois) est
// toléré au chargement : on repart simplement à zéro plutôt que de planter —
// c'est une donnée de confort UX jetable, pas une donnée serveur.
export default class extends Controller {
  static targets = [ "dot", "stepDot", "stepButton", "stepTitle", "stepActions", "counter", "next" ]
  static values = { storageKey: String, total: Number }

  connect() {
    const state = this.load()
    this.done = state.done
    this.current = state.current
    this.render()
  }

  selectStep(event) {
    const i = parseInt(event.currentTarget.dataset.index, 10)
    this.current = this.done[i] ? (this.done[i] = false, i) : i
    this.save()
    this.render()
  }

  finishCurrent() {
    if (this.current == null) return
    this.done[this.current] = true
    const nextUndone = this.done.findIndex((d) => !d)
    this.current = nextUndone === -1 ? null : nextUndone
    this.save()
    this.render()
  }

  render() {
    this.stepButtonTargets.forEach((el, i) => el.classList.toggle("bg-chloro-800", i === this.current))
    this.stepTitleTargets.forEach((el, i) => {
      el.classList.toggle("text-white", i === this.current)
      el.classList.toggle("text-chloro-100", i !== this.current)
    })
    this.stepActionsTargets.forEach((el, i) => { el.hidden = i !== this.current })
    this.stepDotTargets.forEach((el, i) => {
      el.classList.remove("bg-chloro-800", "bg-zest-400", "bg-chloro-400")
      el.classList.add(this.done[i] ? "bg-chloro-400" : i === this.current ? "bg-zest-400" : "bg-chloro-800")
      el.textContent = this.done[i] ? "✓" : ""
    })
    this.dotTargets.forEach((el, i) => {
      el.classList.remove("bg-zest-400", "bg-chloro-400", "bg-chloro-800")
      el.classList.add(this.done[i] ? "bg-chloro-400" : i === this.current ? "bg-zest-400" : "bg-chloro-800")
    })
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = this.current == null ? "Terminé" : `Étape ${this.current + 1} sur ${this.totalValue}`
    }
    if (this.hasNextTarget) {
      this.nextTarget.textContent = this.current == null ? "Session terminée" : "Étape terminée"
      this.nextTarget.disabled = this.current == null
    }
  }

  load() {
    try {
      const raw = JSON.parse(localStorage.getItem(this.storageKeyValue))
      if (raw && Array.isArray(raw.done) && raw.done.length === this.totalValue) {
        return { done: raw.done, current: Number.isInteger(raw.current) ? raw.current : 0 }
      }
    } catch { /* old format or invalid JSON — fall through to a fresh state */ }
    return { done: new Array(this.totalValue).fill(false), current: 0 }
  }

  save() {
    try { localStorage.setItem(this.storageKeyValue, JSON.stringify({ done: this.done, current: this.current })) } catch { /* quota/private mode */ }
  }
}
