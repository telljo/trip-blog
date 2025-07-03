# Preview all emails at http://localhost:3000/rails/mailers/post_mailer
class PostMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/post_mailer/new_post_email
  def new_post_email
    PostMailer.new_post_email(User.first, Post.first)
  end

  def draft_post_email
    PostMailer.draft_post_email(User.first, Post.first)
  end
end
