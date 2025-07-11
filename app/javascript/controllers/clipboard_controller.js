import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["content", "tooltip"];

  static values = {
    confirm: { type: String, default: 'Copied' },
    delayMs: { type: Number, default: 2000 }
  }

  copy(event) {
    const toolTip = new bootstrap.Tooltip(this.tooltipTarget);
    const textToCopy = event.currentTarget.dataset.clipboardCopyValue
    const text = textToCopy || this.contentTarget?.innerText;
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
}
