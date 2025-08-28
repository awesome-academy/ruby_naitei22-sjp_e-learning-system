namespace :user_courses do
  desc I18n.t("tasks.delete_long_time_request.description")
  task cleanup_pending: :environment do
    cutoff_date = 30.days.ago
    pending_requests = UserCourse.where(enrolment_status: :pending)
                                 .where("created_at < ?", cutoff_date)
    count = pending_requests.count
    pending_requests.destroy_all
    puts I18n.t("tasks.delete_long_time_request.success", count:)
  end
end
