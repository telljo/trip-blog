// app/javascript/controllers/modal_controller.js

import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["modal"]
  connect() {
    this.modal = new bootstrap.Modal(this.element)
  }

  open() {
    this.modalTarget.removeAttribute("inert")
    if (!this.modal.isOpened) {
      this.modal.show()
    }
  }

  close() {
    this.modal.hide();
    this.modalTarget.setAttribute("inert", "true")
  }
}