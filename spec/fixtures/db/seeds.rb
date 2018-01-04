# This file will be copied into the dummy app so we can seed that app with
# some basic testable data

require "factory_bot"

FactoryBot.factories.collect(&:name).each {|f| FactoryBot.create_list(f, 5) }
