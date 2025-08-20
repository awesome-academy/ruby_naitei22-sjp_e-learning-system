FactoryBot.define do
  factory :user_word do
    association :user
    association :component
  end
end
