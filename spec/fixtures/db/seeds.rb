# This file will be copied into the dummy app so we can seed that app with
# some basic testable data

require "factory_girl"

FactoryGirl.factories.collect(&:name).inspect

FactoryGirl.create_list(:project_with_milestones, 8)

