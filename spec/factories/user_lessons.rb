FactoryBot.define do
  factory :user_lesson do
    association :user
    association :lesson
    status { 0 }
    grade { 0 }
    completed_at { nil }
  end
end
