FactoryBot.define do
  factory :course do
    sequence(:title){|n| "Sample Course Title #{n}"}
    description{"This is a detailed description of the course."}
    duration{60}

    association :creator, factory: :user
  end
end
