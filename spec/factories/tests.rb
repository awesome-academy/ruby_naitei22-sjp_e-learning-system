FactoryBot.define do
  factory :test do
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    duration { Faker::Number.between(from: 1, to: 60) }
    max_attempts { Faker::Number.between(from: 1, to: 5) }
  end
end
