FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Person #{n}" }
    sequence(:email) { |n| "person_#{n}@example.com" }
    sequence(:phone) { |n| "050123453#{n}" }
    password "foobar12"
    password_confirmation "foobar12"

    factory :admin do
      admin true
    end
  end

  factory :roof do
    area '70'
    declination '10'
    load_capacity '500'
  end

  factory :environment do
    name 'Merenranta'
  end
end
