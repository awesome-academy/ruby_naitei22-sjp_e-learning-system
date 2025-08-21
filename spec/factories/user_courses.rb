FactoryBot.define do
  factory :user_course do
    user
    association :course
    enrolment_status { "pending" }
    progress { 0 }
  end
end
