set :output, "log/cron.log"

every 1.day, at: "4:30 am" do
  rake "registrations:send_pending_notifications_to_all_admins"
end
