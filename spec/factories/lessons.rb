FactoryBot.define do
  factory :lesson do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.sentence }
    position { Faker::Number.between(from: 1, to: 10) }
    association :course
    association :creator, factory: :user
  end
end
