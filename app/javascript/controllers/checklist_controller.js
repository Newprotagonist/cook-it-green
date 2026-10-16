import { Controller } from "@hotwired/stimulus"

// Coche persistée en localStorage (jamais envoyée au serveur) — survit à un
// rechargement pendant les courses. L'état "coché" n'a pas de couleur propre :
// opacité + barré seulement, pour ne pas créer un second accent à côté du zest.
export default class extends Controller {
  static targets = ["item", "count", "bar"]
  static values = { storageKey: String }

  connect() {
    this.checked = this.load()
    this.itemTargets.forEach((el) => this.apply(el))
    this.updateCount()
  }

  toggle(event) {
    const el = event.currentTarget
    const key = el.dataset.key
    this.checked[key] = !this.checked[key]
    this.save()
    this.apply(el)
    this.updateCount()
  }

  apply(el) {
    const on = !!this.checked[el.dataset.key]
    el.classList.toggle("bg-ash-100", on)
    el.classList.toggle("bg-white", !on)
    el.querySelectorAll("[data-checklist-strike]").forEach((n) => {
      n.classList.toggle("line-through", on)
      n.classList.toggle("text-ash-500", on)
    })
    el.querySelectorAll("[data-checklist-box]").forEach((n) => {
      n.classList.toggle("bg-chloro-700", on)
      n.classList.toggle("bg-white", !on)
      n.classList.toggle("border-chloro-700", on)
      n.classList.toggle("border-ash-300", !on)
      n.textContent = on ? "✓" : ""
    })
  }

  updateCount() {
    const total = this.itemTargets.length
    const done = this.itemTargets.filter((el) => this.checked[el.dataset.key]).length
    this.countTargets.forEach((t) => { t.textContent = String(done) })
    if (this.hasBarTarget && total > 0) {
      this.barTargets.forEach((b) => { b.style.width = `${Math.round((done / total) * 100)}%` })
    }
  }

  load() {
    try { return JSON.parse(localStorage.getItem(this.storageKeyValue)) || {} } catch { return {} }
  }

  save() {
    try { localStorage.setItem(this.storageKeyValue, JSON.stringify(this.checked)) } catch { /* quota/private mode */ }
  }
}
