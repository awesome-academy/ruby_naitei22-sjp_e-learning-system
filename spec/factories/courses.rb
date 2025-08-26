FactoryBot.define do
  factory :course do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }

    duration { Faker::Number.between(from: 10, to: 100) }

    association :creator, factory: :admin_user
  end
end
