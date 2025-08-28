FactoryBot.define do
  factory :test_result do
    association :user
    association :component

    attempt_number { 1 }
    mark { Faker::Number.between(from: 0, to: 100) }
    status { 0 }
    submitted { true }

    user_answers do
      {
        "1" => "4",
        "2" => "7",
        "3" => "10"
      }
    end

    trait :in_progress do
      status { 0 }
      submitted { false }
      mark { 0 }
      user_answers { {} }
    end

    trait :low_score do
      mark { Faker::Number.between(from: 0, to: 40) }
    end
  end
end
