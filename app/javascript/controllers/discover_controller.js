import { Controller } from "@hotwired/stimulus"

// Brief, restrained progress beat before revealing discovery results.
export default class extends Controller {
  static targets = ["analyzing", "results", "steps"]
  static values = { fresh: Boolean }

  connect() {
    if (!this.freshValue) return

    this.#runSteps()
  }

  async #runSteps() {
    const items = this.stepsTarget.querySelectorAll("[data-step]")
    const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

    for (let i = 0; i < items.length; i++) {
      items.forEach((el, index) => {
        el.classList.toggle("is-active", index === i)
        el.classList.toggle("is-done", index < i)
      })
      await delay(520)
    }

    items.forEach((el) => {
      el.classList.remove("is-active")
      el.classList.add("is-done")
    })

    await delay(280)
    this.analyzingTarget.classList.add("hidden")
    this.resultsTarget.classList.remove("hidden")

    // Drop ?fresh=1 so refresh doesn't re-animate
    const url = new URL(window.location.href)
    if (url.searchParams.has("fresh")) {
      url.searchParams.delete("fresh")
      window.history.replaceState({}, "", url)
    }
  }
}
