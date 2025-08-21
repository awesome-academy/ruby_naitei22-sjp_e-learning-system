FactoryBot.define do
  factory :answer do
    content{"A sample answer."}
    correct{false}
    association :question

    trait :correct do
      correct{true}
    end
  end
end
