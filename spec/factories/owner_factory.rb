FactoryGirl.define do

  factory :owner do
    name { FFaker::Name.name_with_prefix }
    budget 10000.23

    project
  end

end
