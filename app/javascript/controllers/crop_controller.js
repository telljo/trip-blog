import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

const cropperTemplate = `
  <cropper-canvas background>
    <cropper-image rotatable scalable skewable translatable></cropper-image>
    <cropper-shade hidden></cropper-shade>
    <cropper-handle action="select" plain></cropper-handle>
    <cropper-selection aspect-ratio="1" initial-aspect-ratio="1" initial-coverage="0.9" movable resizable>
      <cropper-grid role="grid" bordered covered></cropper-grid>
      <cropper-crosshair centered></cropper-crosshair>
      <cropper-handle action="move" theme-color="rgba(255, 255, 255, 0.35)"></cropper-handle>
      <cropper-handle action="n-resize"></cropper-handle>
      <cropper-handle action="e-resize"></cropper-handle>
      <cropper-handle action="s-resize"></cropper-handle>
      <cropper-handle action="w-resize"></cropper-handle>
      <cropper-handle action="ne-resize"></cropper-handle>
      <cropper-handle action="nw-resize"></cropper-handle>
      <cropper-handle action="se-resize"></cropper-handle>
      <cropper-handle action="sw-resize"></cropper-handle>
    </cropper-selection>
  </cropper-canvas>
`

// Connects to data-controller="crop"
export default class extends Controller {
  static targets = ["fileInput", "imagePreview", "croppedImageData"]

  connect() {
    this.cropper = null
    this.cropDataUpdateTimeout = null
    this.scheduleCropDataUpdate = this.scheduleCropDataUpdate.bind(this)
  }

  disconnect() {
    this.destroyCropper()
  }

  selectImage(event) {
    const files = event.target.files
    if (files && files.length > 0) {
      const file = files[0]
      const reader = new FileReader()
      reader.onload = (e) => {
        this.imagePreviewTarget.src = e.target.result
        this.initializeCropper()
      }
      reader.readAsDataURL(file)
    }
  }

  initializeCropper() {
    this.destroyCropper()
    this.cropper = new Cropper(this.imagePreviewTarget, {
      template: cropperTemplate
    })

    const selection = this.cropper.getCropperSelection()
    selection?.addEventListener("change", this.scheduleCropDataUpdate)

    const image = this.cropper.getCropperImage()
    image?.$ready().then(() => this.updateCropData()).catch(() => {})
    this.scheduleCropDataUpdate()
  }

  destroyCropper() {
    if (this.cropDataUpdateTimeout) {
      clearTimeout(this.cropDataUpdateTimeout)
      this.cropDataUpdateTimeout = null
    }

    if (this.cropper) {
      const selection = this.cropper.getCropperSelection()
      selection?.removeEventListener("change", this.scheduleCropDataUpdate)
      this.cropper.destroy()
      this.cropper = null
    }
  }

  scheduleCropDataUpdate() {
    if (this.cropDataUpdateTimeout) {
      clearTimeout(this.cropDataUpdateTimeout)
    }

    this.cropDataUpdateTimeout = setTimeout(() => this.updateCropData(), 100)
  }

  async updateCropData() {
    const cropper = this.cropper
    const selection = this.cropper?.getCropperSelection()
    if (!selection || selection.hidden || selection.width === 0 || selection.height === 0) return

    const canvas = await selection.$toCanvas()
    if (this.cropper !== cropper) return

    this.croppedImageDataTarget.value = canvas.toDataURL("image/png")
  }
}
