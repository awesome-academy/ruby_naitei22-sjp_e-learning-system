FactoryBot.define do
  factory :component do
    component_type{0}
    index_in_lesson{1}
    association :lesson
  end
end
