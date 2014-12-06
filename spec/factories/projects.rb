
FactoryGirl.define do

  factory :project do
    title 'project 1'
    value_as_text  "some text\n<storing>nonsense</storing>"
    value_as_string "this is a string"
    value_as_boolean true
    value_as_double 2.356
    value_as_datetime Time.now
    value_as_integer 23

    factory :project_user do
      user
      owner
    end
  end




end
