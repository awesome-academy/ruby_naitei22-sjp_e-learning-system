namespace :cleanup do
  desc I18n.t("tasks.cleanup.description")
  task cleanup_rejected_requests: :environment do
    cutoff_date = 90.days.ago
    scope = UserCourse.where(enrolment_status: :rejected)
                      .where("updated_at < ?", cutoff_date)
    count = scope.count
    puts I18n.t("tasks.cleanup.found", count:)
    scope.destroy_all
    puts I18n.t("tasks.cleanup.success", count:)
  end
end
