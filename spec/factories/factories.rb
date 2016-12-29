FactoryGirl.define do

  factory :user do
    title 'mr'
    first_name 'ben'
  end

  factory :loader_release do
    sequence(:name) { |n| "Loader Release V#{n}" }

    project

    version
  end

end
