FactoryBot.define do
  factory :admin_course_manager do
    association :user
    association :course
  end
end
