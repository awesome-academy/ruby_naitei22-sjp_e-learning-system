FactoryBot.define do
  factory :user_lesson do
    association :user
    association :lesson
  end
end
