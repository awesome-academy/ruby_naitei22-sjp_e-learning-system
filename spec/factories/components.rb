FactoryBot.define do
  factory :component do
    association :lesson
    index_in_lesson { Faker::Number.between(from: 1, to: 10) }

    factory :word_component do
      association :lesson
      index_in_lesson { Faker::Number.between(from: 1, to: 10) }
      component_type { :word }
      association :word
      content { nil }
      test_id { nil }
    end

    factory :test_component do
      component_type { :test }
      association :test
      content { nil }
      word_id { nil }
    end

    factory :paragraph_component do
      component_type { :paragraph }
      content { Faker::Lorem.paragraph }
      word_id { nil }
      test_id { nil }
    end
  end
end
