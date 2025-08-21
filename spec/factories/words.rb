FactoryBot.define do
  factory :word do
    content { Faker::Lorem.unique.word }
    meaning { Faker::Lorem.sentence }
    word_type { "noun" }
  end
end
