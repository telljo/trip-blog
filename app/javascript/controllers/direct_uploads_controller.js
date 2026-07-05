import { Controller } from "@hotwired/stimulus"
import { DirectUploadController } from "@rails/activestorage"

export default class extends Controller {
  static values = { concurrency: { type: Number, default: 3 } }

  connect() {
    this.queue = []
    this.activeUploads = 0
    this.pendingUploads = 0
    this.submitRequested = false
    this.submitter = null
  }

  upload(event) {
    const input = event.currentTarget
    const files = Array.from(input.files)

    if (files.length === 0) return

    // The upload controllers retain the File objects. Clearing the input keeps
    // Active Storage's submit hook from uploading the same files a second time.
    input.value = ""

    this.pendingUploads += files.length
    files.forEach(file => {
      this.queue.push({ input, file })
    })

    this.startAvailableUploads()
  }

  submit(event) {
    if (this.pendingUploads === 0) return

    event.preventDefault()
    this.submitRequested = true
    this.submitter = event.submitter
  }

  startAvailableUploads() {
    while (this.activeUploads < this.concurrencyValue && this.queue.length > 0) {
      const { input, file } = this.queue.shift()
      const upload = new DirectUploadController(input, file)

      this.activeUploads += 1
      upload.start(error => this.uploadFinished(error))
    }
  }

  uploadFinished(error) {
    this.activeUploads -= 1
    this.pendingUploads -= 1

    if (error) {
      // Do not auto-submit a form after a failed upload. A later, deliberate
      // submit can still save any files that uploaded successfully.
      this.submitRequested = false
      this.submitter = null
    }

    this.startAvailableUploads()

    if (this.pendingUploads === 0 && this.submitRequested) {
      const submitter = this.submitter

      this.submitRequested = false
      this.submitter = null

      if (submitter) {
        this.element.requestSubmit(submitter)
      } else {
        this.element.requestSubmit()
      }
    }
  }
}
