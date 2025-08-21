FactoryBot.define do
  factory :question do
    content{"What is the capital of Vietnam?"}
    question_type{0}
    association :test
    transient do
      answers_count{4}
    end

    before(:create) do |question, evaluator|
      question.answers.build(attributes_for(:answer, :correct))

      (evaluator.answers_count - 1).times do
        question.answers.build(attributes_for(:answer))
      end
    end
  end
end
