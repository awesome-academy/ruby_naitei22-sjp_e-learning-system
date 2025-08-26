FactoryBot.define do
  factory :user_course do
    association :user
    association :course
    enrolment_status { :pending }
  end
end
