FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { 'password123' }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :superadmin do
      role { :superadmin }
    end
  end
end
