class AdminNotifierMailer < ApplicationMailer
  def pending_registrations admin, pending_registrations_by_course
    @admin = admin
    @pending_registrations_by_course = pending_registrations_by_course
    mail(
      to: @admin.email,
      subject: t("admin_notifier.pending_registrations.subject")
    )
  end
end
