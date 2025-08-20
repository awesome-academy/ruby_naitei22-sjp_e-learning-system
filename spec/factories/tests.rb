FactoryBot.define do
  factory :test do
    sequence(:name){|n| "Sample Test #{n}"}
    description{"A comprehensive description for the sample test."}
    duration{1800}
    max_attempts{5}
  end
end
