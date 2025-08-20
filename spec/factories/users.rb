# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { "password" }
    password_confirmation { "password" }
    birthday { Faker::Date.birthday(min_age: 18, max_age: 65) }
    gender { User.genders.keys.sample }

    trait :oauth do
      provider { "google_oauth2" }
      uid { Faker::Internet.uuid }
      email { Faker::Internet.unique.email }
      password { "password" }
      password_confirmation { "password" }
      birthday { nil }
      gender { nil }
    end
  end
end
