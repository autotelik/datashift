FactoryBot.define do

  factory :category do
    sequence(:reference) { |n| "category_00#{n}" }
    name { FFaker::Name.unique.name }
  end

end
