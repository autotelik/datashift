# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::
# License::   MIT
#
ENV["RAILS_ENV"] ||= 'test'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

# Need an active record DB to test against, so we manage own Rails sandbox
Sandbox.gen_rails_sandbox

require File.expand_path("../rails_sandbox/config/environment.rb",  __FILE__)

require 'factory_girl_rails'
require 'database_cleaner'

require File.expand_path("../../lib/datashift", __FILE__)

RSpec.configure do |config|

  config.before(:suite) do
    # make sure we have dir for result files
    FileUtils.mkdir_p(results_path()) unless File.exist?(results_path)
  end

  config.include FactoryGirl::Syntax::Methods

end
