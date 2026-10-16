import { Controller } from "@hotwired/stimulus"

// Niveau "Lourde" : confirmation en deux temps puis barre de progression
// chronométrée pendant l'envoi. Le recalcul est un vrai POST synchrone
// (~800 ms, voir NutritionTargetsController#recalculate) sans événements de
// progression réels — la barre est une animation approximative calée sur
// submit-start/submit-end, pas une mesure exacte, pour donner le même retour
// visuel que la maquette sans changement côté serveur.
export default class extends Controller {
  static targets = [ "idle", "confirm", "running", "form", "bar" ]

  ask() {
    this.idleTarget.hidden = true
    this.confirmTarget.hidden = false
  }

  cancel() {
    this.confirmTarget.hidden = true
    this.idleTarget.hidden = false
  }

  go() {
    this.confirmTarget.hidden = true
    this.runningTarget.hidden = false
    this.barTarget.style.transition = "none"
    this.barTarget.style.width = "0%"
    requestAnimationFrame(() => {
      this.barTarget.style.transition = "width 900ms ease-out"
      this.barTarget.style.width = "100%"
    })
    this.formTarget.requestSubmit()
  }
}
