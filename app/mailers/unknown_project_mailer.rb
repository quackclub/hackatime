class UnknownProjectMailer < ApplicationMailer
  def notify_unknown_project(user)
    @user = user
    mail(
      to: @user.email_addresses.first&.email,
      subject: "Help us attribute your time — set your project"
    )
  end
end
