FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "Project #{n}" }
    description { Faker::Lorem.sentence }
    active { true }
    settings { {} }

    trait :inactive do
      active { false }
    end

    trait :with_integrations do
      after(:create) do |project|
        create_list(:integration, 2, project: project)
      end
    end

    trait :with_users do
      after(:create) do |project|
        create_list(:user_project, 3, project: project)
      end
    end
  end
end
