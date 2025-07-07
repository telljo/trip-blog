import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle-content"
export default class extends Controller {
  static targets = ['contentPreview', 'contentBody', 'contentButton']

  toggle() {
    if (this.contentPreviewTarget.classList.contains('visually-hidden')) {
      this.contentButtonTarget.textContent = 'Read More';
    } else {
      this.contentButtonTarget.textContent = 'Read Less';
    }

    this.contentPreviewTarget.classList.toggle('visually-hidden');
    this.contentBodyTarget.classList.toggle('visually-hidden');
  }
}
