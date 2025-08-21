FactoryBot.define do
  factory :lesson do
    sequence(:title){|n| "Sample Lesson Title #{n}"}
    description{"This is a detailed description of the lesson."}
    position{1}

    association :course
    association :creator, factory: :user
  end
end
