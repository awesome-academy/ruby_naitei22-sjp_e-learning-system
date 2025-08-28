FactoryBot.define do
  factory :question do
    association :test
    content { Faker::Lorem.sentence }
    question_type { :single_choice }

    after(:build) do |question|
      if question.answers.empty?
        question.answers << build(:answer, correct: true, question: question)
      end
    end
  end
end
