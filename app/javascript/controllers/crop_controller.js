import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="crop"
export default class extends Controller {
  static targets = ["fileInput", "imagePreview", "croppedImageData"]

  connect() {
    this.cropper = null;
  }

  selectImage(event) {
    const files = event.target.files;
    if (files && files.length > 0) {
      const file = files[0];
      const reader = new FileReader();
      reader.onload = (e) => {
        this.imagePreviewTarget.src = e.target.result;
        if (this.cropper) {
          this.cropper.destroy();
        }
        this.cropper = new Cropper(this.imagePreviewTarget, {
          aspectRatio: 1,
          viewMode: 1,
          crop: () => {
            const canvas = this.cropper.getCroppedCanvas();
            this.croppedImageDataTarget.value = canvas.toDataURL('image/png');
          }
        });
      };
      reader.readAsDataURL(file);
    }
  }
}
