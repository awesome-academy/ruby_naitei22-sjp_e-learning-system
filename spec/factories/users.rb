FactoryBot.define do
  factory :user do
    sequence(:email){|n| "user#{n}@example.com"}
    name{"Test User"}
    password{"password123"}
    password_confirmation{"password123"}
    birthday{"2000-01-01"}
    gender{"male"}
    role{"user"} # Default role

    # Define a trait for an admin user
    trait :admin do
      role{"admin"}
    end
  end
end
