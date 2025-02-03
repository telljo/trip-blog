# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/email_verification
  def email_verification
    UserMailer.with(user: User.first).email_verification
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/password_reset
  def password_reset
    UserMailer.with(user: User.first).password_reset
  end
end
