FactoryBot.define do
  factory :test_result do
    association :user
    association :component
    attempt_number { Faker::Number.between(from: 1, to: 3) }
    mark { Faker::Number.between(from: 0, to: 100) }
    status { :failed }
    submitted { false }
    user_answers { {} }
  end
end
