namespace :registrations do
  desc "Sends a daily email to all admins about
      new pending course registrations."

  task send_pending_notifications_to_all_admins: :environment do
    pending_user_courses = UserCourse.pending.includes(:user, :course)

    if pending_user_courses.any?
      puts "Found #{pending_user_courses.count} pending registrations.
            Processing..."

      pending_by_course = pending_user_courses.group_by(&:course)

      admins = User.where(role: "admin")

      admins.each do |admin|
        puts "  -> Notifying admin: #{admin.email}"
        AdminNotifierMailer.pending_registrations(admin,
                                                  pending_by_course).deliver_now
      end

      puts "Finished sending notifications to all admins."
    else
      puts "No pending registrations found. No email sent."
    end
  end
end
