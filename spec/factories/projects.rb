
FactoryGirl.define do

  factory :project do

    sequence(:title) { |n| "Title #{n}" }

    value_as_text  "some text\n<storing>nonsense</storing>"
    value_as_string "this is a string"
    value_as_boolean true
    value_as_double 2.356
    value_as_datetime Time.now
    value_as_integer 23

    association :user, factory: :user

    factory :project_with_user do
      user
      owner

      factory :project_with_milestones do

        # milestone_count is declared as a transient attribute and available in
        # attributes on the factory, as well as the callback via the evaluator
        transient do
          milestones_count 5
        end

        # the after(:create) yields two values; the project instance itself and the
        # evaluator, which stores all values from the factory, including transient
        # attributes; `create_list`'s second argument is the number of records
        # to create and we make sure the project is associated properly to the milestone
        after(:create) do |project, evaluator|
          create_list(:milestone_with_project, evaluator.milestones_count, project: project)
        end
      end
    end

  end

end
