FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { Faker::Internet.email }
    password { "password" }

    birthday { "2000-01-01" }
    gender { 0 }
    role { 0 }

    factory :admin_user do
      role { 1 }
    end
  end
end
