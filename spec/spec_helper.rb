# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::
# License::   MIT
#
ENV["RAILS_ENV"] ||= 'test'

require "simplecov"
SimpleCov.start

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each { |f| require f }

# Need an active record DB to test against, so we manage own Rails sandbox
DataShift::Sandbox.gen_rails_sandbox


require File.join( DataShift::Sandbox.rails_sandbox_path, "config/environment.rb")
require "rspec/rails"


require 'factory_girl_rails'
require 'database_cleaner'

require File.expand_path("../../lib/datashift", __FILE__)

RSpec.configure do |config|

  #config.use_transactional_fixtures = false

  config.before(:suite) do
    # make sure we have dir for result files
    FileUtils.mkdir_p(results_path()) unless File.exist?(results_path)
  end

  config.before(:each) do
    DataShift::Configuration.reset
    DataShift::Exporters::Configuration.reset
    DataShift::Loaders::Configuration.reset
  end

  config.include FactoryGirl::Syntax::Methods

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  config.before do |example|
    md = example.metadata
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean_with :truncation, except: %w(ar_internal_metadata)
  end

end
