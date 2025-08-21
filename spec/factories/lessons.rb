FactoryBot.define do
  factory :lesson do
    association :course
    title { "Sample Lesson" }
    description { "This is a test lesson." }
    position { 1 }
    association :creator, factory: :user
  end
end
