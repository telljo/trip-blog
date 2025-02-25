import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="expand-replies"
export default class extends Controller {
  static targets = ["replies", "hideRepliesButton", "showRepliesButton", "cancelReplyButton", "replyForm"];

  connect() {
  }

  showReplyForm() {
      this.replyFormTarget.classList.remove("visually-hidden");
  }

  showReplies() {
    this.repliesTarget.classList.remove("visually-hidden");
    this.hideRepliesButtonTarget.classList.remove("visually-hidden");
    this.showRepliesButtonTarget.classList.add("visually-hidden");
  }

  hideReplies() {
    this.repliesTarget.classList.add("visually-hidden");
    this.hideRepliesButtonTarget.classList.add("visually-hidden");
    this.showRepliesButtonTarget.classList.remove("visually-hidden");
  }
}
