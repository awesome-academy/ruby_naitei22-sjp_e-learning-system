FactoryBot.define do
  factory :component do
    association :lesson
    component_type { 0 }
    sequence(:index_in_lesson) { |n| n }
    content { "Sample component" }
  end
end
