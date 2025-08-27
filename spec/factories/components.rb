FactoryBot.define do
  factory :component do
    association :lesson
    index_in_lesson { Faker::Number.between(from: 1, to: 10) }
    component_type { :paragraph }

    factory :word_component do
      component_type { :word }
      association :word
      content { nil }
    end

    factory :test_component do
      component_type { :test }
      association :test
      content { nil }
    end

    factory :paragraph_component do
      component_type { :paragraph }
      content { Faker::Lorem.paragraph }
      word_id { nil }
      test_id { nil }
    end
  end
end
