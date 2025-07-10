import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["content", "button"];

  static values = {
    copyText: { type: String, default: null },
    confirm: { type: String, default: 'Copied' },
    delayMs: { type: Number, default: 2000 }
  }

  copy() {
    const toolTip = new bootstrap.Tooltip(this.buttonTarget);
    const text = this.copyTextValue || this.contentTarget?.innerText;
    if(text) {
      navigator.clipboard.writeText(text).then(() => {
          toolTip.toggle();

          setTimeout(() => {
            toolTip.toggle();
          }, this.delayMsValue);
        })
        .catch((error) => {
          console.error('Failed to copy text to clipboard:', error);
        });
    }
  }

  copyCurrentUrl() {
    const currentUrl = window.location.href;

    this.copyTextValue = currentUrl;
    this.copy();
  }
}
