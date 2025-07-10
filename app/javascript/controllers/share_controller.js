import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
  static targets = ['shareButton'];

  connect() {
  }

  async sharePost() {
    const shareButtonElement = this.shareButtonTarget;
    shareButtonElement.innerHTML = '';
    const post = JSON.parse(shareButtonElement.dataset.post);

    const blobImage = post.image.blob;
    const fileName = blobImage.filename;
    const filesArray = [
      new File([blobImage], fileName, {
        type: 'image/png',
        lastModified: Date.now(),
      }),
    ]
    const shareData = {
      title: fileName,
      files: filesArray,
      url: document.location.origin,
    }
    if (navigator.canShare && navigator.canShare(shareData)) {
      await navigator.share(shareData)
    }
  }
}
