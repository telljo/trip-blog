class ApplicationMailer < ActionMailer::Base
  helper(EmailHelper)

  default from: "jtell1997@gmail.com"
  layout "mailer"
end
