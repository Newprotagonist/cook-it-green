import { Controller } from "@hotwired/stimulus"

// Niveau "Routine" : le bouton Enregistrer reste inactif tant qu'aucun champ
// n'a changé, pour qu'il n'y ait jamais de clic sur un formulaire inchangé.
export default class extends Controller {
  static targets = [ "submit" ]

  markDirty() {
    if (this.hasSubmitTarget) this.submitTarget.disabled = false
  }
}
