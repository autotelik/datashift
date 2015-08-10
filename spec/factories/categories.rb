FactoryGirl.define do

  factory :category do
    sequence(:reference) { |n| "category_00#{n}" }
  end

  puts "DONE DOEN CATEGORy"

end
