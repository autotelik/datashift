# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Spec Helper for Active Record Loader
#
#
# We are not setup as a Rails project so need to mimic an active record database setup so
# we have some  AR models to test against. Create an in memory database from scratch.
#
require 'active_record'
require 'bundler'
require 'stringio'

require File.dirname(__FILE__) + '/../lib/datashift'

$DataShiftFixturePath = File.join(File.dirname(__FILE__), 'fixtures')
$DataShiftDatabaseYml = File.join($DataShiftFixturePath, 'config/database.yml')

module DataShift
    
  def bundler_setup(gemfile)
    ENV['BUNDLE_GEMFILE'] = gemfile
    Bundler.setup
  end
  
  def db_clear_connections
    # We have multiple schemas and hence connections tested in single spec directory   
    ActiveRecord::Base.clear_active_connections!()   
  end
  
  def db_connect( env = 'test_file')

    bundler_setup( File.join(DataShift::root_path, 'spec', 'Gemfile') )
    
    # Some active record stuff seems to rely on the RAILS_ENV being set ?

    ENV['RAILS_ENV'] = env
 
    # We have multiple schemas and hence connections tested in single spec directory   
    db_clear_connections
     
    configuration = {}

    configuration[:database_configuration] = YAML::load( ERB.new(IO.read($DataShiftDatabaseYml)).result )
    db = configuration[:database_configuration][ env ]

    puts "Setting DB Config - #{db.inspect}"
    ActiveRecord::Base.configurations = db
    
    #dbtype = Rails.configuration.database_configuration[Rails.env]['adapter'].to_sym

    set_logger
    
    puts "Connecting to DB"
    
    ActiveRecord::Base.establish_connection( db )

    # See errors  #<NameError: uninitialized constant RAILS_CACHE> when doing save (AR without Rails)
    # so copied this from ... Rails::Initializer.initialize_cache
    #Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store( :memory_store ) unless defined?(RAILS_CACHE)

    puts "Connected to DB"
    
    @dslog.info "Connected to DB - #{ActiveRecord::Base.connection.inspect}"
  end

  def set_logger
    
    require 'logger'
    logdir = File.dirname(__FILE__) + '/logs'
    FileUtils.mkdir_p(logdir) unless File.exists?(logdir)
    ActiveRecord::Base.logger = Logger.new(logdir + '/datashift_spec.log')

    # Anyway to direct one logger to another ????? ... Logger.new(STDOUT)
    
    @dslog = ActiveRecord::Base.logger
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

module SpecHelper
  
  # VERSIONS of Spree (1.1.0.rc1, 1.0.0, 0.11.2)
  
  $SpreeFixturePath = File.join($DataShiftFixturePath, 'spree')    
  $SpreeNegativeFixturePath = File.join($DataShiftFixturePath, 'negative')
    
  def self.spree_fixture( source)
    File.join($SpreeFixturePath, source)
  end
  
  def before_all_spree 

    # we are not a Spree project, nor is it practical to externally generate
    # a complete Spree application for testing so we implement a mini migrate/boot of our own
    #       
    SpreeHelper.boot('test_spree_standalone')             # key to YAML db e.g  test_memory, test_mysql
    
    puts "Testing Spree standalone - version #{SpreeHelper::version}"
        
    SpreeHelper.migrate_up      # create an sqlite Spree database on the fly
    
    @spree_klass_list  =  %w{Image OptionType OptionValue Property ProductProperty Variant Taxon Taxonomy Zone}
    
    @klass = SpreeHelper::get_product_class
    @Product_klass = @klass  
  
    @spree_klass_list.each do |k|
      instance_variable_set("@#{k}_klass", SpreeHelper::get_spree_class(k)) 
    end
    
  end
  
  def before_each_spree
      
    # Reset main tables - TODO should really purge properly, or roll back a transaction      
    @Product_klass.delete_all
    
    @spree_klass_list.each do |k| z = SpreeHelper::get_spree_class(k); 
      if(z.nil?)
        puts "WARNING: Failed to find expected Spree CLASS #{k}" 
      else
        SpreeHelper::get_spree_class(k).delete_all 
      end
    end
  end
      
end

  
RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  alias :silence :capture
end