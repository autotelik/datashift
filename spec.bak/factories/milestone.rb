FactoryGirl.define do

  factory :milestone do
    sequence(:name) { |n| "milestone #{n}" }
    cost 100
    datetime Time.new

    factory :milestone_with_project do
      project
    end

  end

end
