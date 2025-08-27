set :environment, "development"
set :output, "log/cron.log"
env :PATH, ENV["PATH"]

every 1.day, at: "12:00 am" do
  rake "user_courses:cleanup_pending"
end
