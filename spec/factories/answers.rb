FactoryBot.define do
  factory :answer do
    association :question
    content { Faker::Lorem.sentence }
    correct { true }
  end
end
