import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-post"
export default class extends Controller {
  static targets = ['postPreview', 'postBody', 'postButton']

  toggle() {
    if (this.postPreviewTarget.classList.contains('visually-hidden')) {
      this.postButtonTarget.textContent = 'Read More';
    } else {
      this.postButtonTarget.textContent = 'Read Less';
    }

    this.postPreviewTarget.classList.toggle('visually-hidden');
    this.postBodyTarget.classList.toggle('visually-hidden');
  }
}
