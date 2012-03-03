require 'erb'
require 'yaml'

require File.dirname(__FILE__) + '/../lib/datashift'

include DataShift

#.# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spec Helper for Active Record Loader
#
#
# We are not setup as a Rails project so need to mimic an active record database setup so
# we have some  AR models top test against. Create an in memory database from scratch.
#
$DataShiftFixturePath = File.join(File.dirname(__FILE__), 'fixtures')
$DataShiftDatabaseYml = File.join($DataShiftFixturePath, 'config/database.yml')

module DataShift
 

  def db_connect( env = 'test_file', version = nil)

    version ? gem('activerecord', version) : gem('activerecord')
    
    require 'active_record'

    # Some active record stuff seems to rely on the RAILS_ENV being set ?

    ENV['RAILS_ENV'] = env
  
    configuration = {}

    configuration[:database_configuration] = YAML::load( ERB.new(IO.read($DataShiftDatabaseYml)).result )
    db = configuration[:database_configuration][ env ]

    puts "Setting DB Config - #{db.inspect}"
    ActiveRecord::Base.configurations = db

    #ActiveRecord::Base.logger = Logger.new(STDOUT)

    require 'logger'
    logdir = File.dirname(__FILE__) + '/logs'
    FileUtils.mkdir_p(logdir) unless File.exists?(logdir)
    ActiveRecord::Base.logger = Logger.new(logdir + '/datashift_spec.log')

    @ilog = ActiveRecord::Base.logger

    puts "Connecting to DB"
    ActiveRecord::Base.establish_connection( db )

    # See errors  #<NameError: uninitialized constant RAILS_CACHE> when doing save (AR without Rails)
    # so copied this from ... Rails::Initializer.initialize_cache
    Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store( :memory_store )

    @ilog.info "Connected to DB - #{ActiveRecord::Base.connection.inspect}"
  end

  # These are our test models with associations
  def db_clear
    [Project, Milestone, Category, Version, LoaderRelease].each {|x| x.delete_all}
  end

  def load_in_memory
    load "#{Rails.root}/db/schema.rb"
  end

  def migrate_up
    ActiveRecord::Migrator.up(  File.dirname(__FILE__) + '/db/migrate')
  end

  def results_path
    File.join($DataShiftFixturePath, 'results')
  end
  
  def results_clear
    begin FileUtils.rm_rf(results_path); rescue; end
    
    FileUtils.mkdir(results_path) unless File.exists?(results_path);
  end
  
  # Return location of an expected results file and ensure tree clean before test
  def result_file( name )
    expect = File.join(results_path, name)

    begin FileUtils.rm(expect); rescue; end

    expect
  end

  def ifixture_file( name )
    File.join($DataShiftFixturePath, name)
  end

end


RSpec.configure do |config|
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures  = false
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures'

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end