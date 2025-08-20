FactoryBot.define do
  factory :course do
    sequence(:title) { |n| "Course #{n}" }
    description { "This is a test course description." }
    duration { 10 }
    association :creator, factory: :user
  end
end
