import { Controller } from "@hotwired/stimulus"

// Poll analysis status and advance the progress checklist.
export default class extends Controller {
  static targets = ["steps"]
  static values = {
    id: Number,
    status: String,
    pollUrl: String,
    doneUrl: String
  }

  connect() {
    if (this.statusValue === "completed" || this.statusValue === "failed") return

    this.stepIndex = 0
    this.stepTimer = setInterval(() => this.#advanceStep(), 900)
    this.pollTimer = setInterval(() => this.#poll(), 1200)
    this.#poll()
  }

  disconnect() {
    clearInterval(this.stepTimer)
    clearInterval(this.pollTimer)
  }

  #advanceStep() {
    if (!this.hasStepsTarget) return
    const items = this.stepsTarget.querySelectorAll("[data-step]")
    if (this.stepIndex < items.length - 1) this.stepIndex += 1
    items.forEach((el, index) => {
      el.classList.toggle("is-active", index === this.stepIndex)
      el.classList.toggle("is-done", index < this.stepIndex)
    })
  }

  async #poll() {
    try {
      const response = await fetch(this.pollUrlValue, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) return
      const data = await response.json()

      if (data.status === "completed" || data.status === "failed") {
        clearInterval(this.stepTimer)
        clearInterval(this.pollTimer)
        window.location.href = data.status === "completed" ? "/?analysed=1" : `/analyses/${this.idValue}`
      }
    } catch (_) {
      // keep polling
    }
  }
}
