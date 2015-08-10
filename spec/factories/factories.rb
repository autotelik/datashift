FactoryGirl.define do

  factory :user do
    title 'mr'
    first_name 'ben'
  end

  factory :owner do
    name 'i am the owner'
    budget 10000.23
  end


  factory :loader_release do
    sequence(:name) { |n| "Loader Release V#{n}" }
  end

end
