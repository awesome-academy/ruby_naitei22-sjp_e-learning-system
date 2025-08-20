FactoryBot.define do
  factory :test_result do
    association :user
    association :component
    attempt_number { 1 }
    user_answers { { "q1" => "a1" } }
    mark { 10 }
    status { 0 }
    submitted { false }
  end
end
