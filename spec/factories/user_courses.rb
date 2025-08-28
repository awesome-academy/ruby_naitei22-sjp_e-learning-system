FactoryBot.define do
  factory :user_course do
    association :user
    association :course
    enrolment_status { :pending }
    progress { 0 }
    reason { nil }
    start_date { nil }
    end_date { nil }
  end
end
