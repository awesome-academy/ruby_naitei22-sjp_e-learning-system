FactoryBot.define do
  factory :word do
    content{Faker::Lorem.word}
    meaning{Faker::Lorem.sentence}
    word_type{Word.word_types.keys.sample}
  end
end
