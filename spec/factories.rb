# encoding: UTF-8
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
    before(:create) do |roof|
      environment = FactoryGirl.create(:environment)
    end
    area '70'
    declination '1'
    load_capacity '500'
  end

  factory :environment do
    name 'Merenranta'
  end

  factory :plant do
    sequence(:name) { |n| "Example Plant #{n}" }
    sequence(:latin_name) { |n| "Plantus Examplus #{n}" }
    height 1
    colour "Green"
    min_soil_thickness 20
    weight 1
    note "Totally fabulous plant"
  end

  factory :greenroof do
    before(:create) do |greenroof|
      plants = [FactoryGirl.create(:plant), FactoryGirl.create(:plant)]
      #user = FactoryGirl.create(:user)
      bases = [FactoryGirl.build(:base), FactoryGirl.build(:base)]
      #roof = FactoryGirl.build(:roof)
    end
    roof { |a| a.association(:roof) }
    user { |a| a.association(:user) }
    address "Emminkatu 1"
    constructor "Laurin viherpiperrys kommandiittiyhtiö"
    purpose 1
    note "Viherkattotiimi on hienoin"
    year 1984
  end

  factory :layer do
    sequence(:name) { |n| "Kiisseli #{n}" }
    product_name "Repan kiisseli"
    thickness 10
    weight 100
  end

  factory :base do
    before(:create) do |base|
      layers = [FactoryGirl.create(:layer), FactoryGirl.create(:layer)]
    end
    absorbancy 100
    note "Tämä on superlaadukas pohj-- kasvualusta."
  end
end

