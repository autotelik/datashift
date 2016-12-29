FactoryGirl.define do

  factory :version do

    name { FFaker::Currency.code }
  end

end

