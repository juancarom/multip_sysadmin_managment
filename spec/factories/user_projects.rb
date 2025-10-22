FactoryBot.define do
  factory :user_project do
    association :user
    association :project
    role { :member }

    trait :admin do
      role { :admin }
    end
  end
end
