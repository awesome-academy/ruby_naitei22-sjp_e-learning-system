FactoryBot.define do
  factory :user_word do
    association :user

    association :component, factory: :word_component
  end
end
