import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="notice"
export default class extends Controller {
  connect() {
    this.alert = bootstrap.Alert.getOrCreateInstance(this.element)
    this.timeout = window.setTimeout(() => {
      this.alert.close()
    }, 4000)
  }

  disconnect() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
    }
  }
}
