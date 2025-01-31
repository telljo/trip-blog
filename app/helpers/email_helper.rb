module EmailHelper
  def email_image_tag(image, **options)
    attachments[image] = File.read(Rails.root.join("app/assets/favicon/#{image}"))
    image_tag attachments[image].url, **options
  end
end
