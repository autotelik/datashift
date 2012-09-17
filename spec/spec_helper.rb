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
require 'thor/actions'
require 'bundler'
require 'stringio'

require File.dirname(__FILE__) + '/../lib/datashift'

require 'spree_helper'

$DataShiftFixturePath = File.join(File.dirname(__FILE__), 'fixtures')
$DataShiftDatabaseYml = File.join($DataShiftFixturePath, 'config/database.yml')

module DataShift
    
  def bundler_setup(gemfile)
    ENV['BUNDLE_GEMFILE'] = gemfile
    #Bundler.setup
    begin
      Bundler.setup(:default, :development)
    rescue Bundler::BundlerError => e
      $stderr.puts e.message
      $stderr.puts "Run `bundle install` to install missing gems"
      exit e.status_code
    end
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

  def self.rails_sandbox
    
    rails_sandbox = File.expand_path('../../spec/datashift_rails_sandbox', __FILE__)
     
    puts "Creating new Rails sandbox : ", File.expand_path( "#{rails_sandbox}/.." )
    
    unless(File.exists?(rails_sandbox))
      run_in( File.expand_path("#{rails_sandbox}/..") ) do |path|
          
        puts "Creating new Rails sandbox : #{path}"
        system('rails new datashift_rails_sandbox')

        puts "Using Rails sandbox : #{path}"
      end
    end
    rails_sandbox
  end
  
end

  
RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  def run_in(dir )
    puts "RSpec .. running test in path [#{dir}]"
    original_dir = Dir.pwd
    begin
      Dir.chdir dir
      yield
    ensure
      Dir.chdir original_dir
    end
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
  
  def ifixture_file( name )
    File.join($DataShiftFixturePath, name)
  end
  
  module RSpecSpreeHelper
    # VERSIONS of Spree (1.1.0.rc1, 1.0.0, 0.11.2)
  
    include Thor::Actions 
    
    $SpreeFixturePath = File.join($DataShiftFixturePath, 'spree')    
    $SpreeNegativeFixturePath = File.join($DataShiftFixturePath, 'negative')   
  
    def self.spree_sandbox 
      File.join(File.dirname(__FILE__), 'sandbox')
    end
  
    def self.spree_fixture( source)
      File.join($SpreeFixturePath, source)
    end
  
    def set_spree_class_helpers
      @spree_klass_list  =  %w{Image OptionType OptionValue Property ProductProperty Variant Taxon Taxonomy Zone}
    
      @Product_klass = DataShift::SpreeHelper::get_product_class  
  
      @spree_klass_list.each do |k|
        instance_variable_set("@#{k}_klass", DataShift::SpreeHelper::get_spree_class(k)) 
      end
    end
  
    def before_all_spree 

      # we are not a Spree project, nor is it practical to externally generate
      # a complete Spree application for testing so we implement a mini migrate/boot of our own
      #       
      RSpecSpreeHelper::boot('test_spree_standalone')             # key to YAML db e.g  test_memory, test_mysql
    
      puts "Testing Spree standalone - version #{DataShift::SpreeHelper::version}"
        
      RSpecSpreeHelper::migrate_up      # create an sqlite Spree database on the fly
    
      set_spree_class_helpers
    
    end
  
    def before_each_spree
      
      # Reset main tables - TODO should really purge properly, or roll back a transaction      
      @Product_klass.delete_all
    
      @spree_klass_list.each do |k| z = DataShift::SpreeHelper::get_spree_class(k); 
        if(z.nil?)
          puts "WARNING: Failed to find expected Spree CLASS #{k}" 
        else
          DataShift::SpreeHelper::get_spree_class(k).delete_all 
        end
      end
    end
     
    # Datashift is usually included and tasks pulled in by a parent/host application.
    # So here we are hacking our way around the fact that datashift is not a Rails/Spree app/engine
    # so that we can ** run our specs ** directly in datashift library
    # i.e without ever having to install datashift in a host application
    #
    # NOTES:
    # => Will chdir into the sandbox to load environment as need to mimic being at root of a rails project
    #    chdir back after environment loaded
    
    def self.boot( database_env)
     
      ActiveRecord::Base.clear_active_connections!() 
      
      if( ! DataShift::SpreeHelper::is_namespace_version )
        
        DataShift::SpreeHelper::load() 
        
        db_connect( database_env )
        @dslog.info "Booting Spree using pre 1.0.0 version"
        boot_pre_1
        @dslog.info "Booted Spree using pre 1.0.0 version"
      else

        #require 'rails/all'
        
        store_path = Dir.pwd
        
        spree_sandbox_app_path = spree_sandbox
        
        unless(File.exists?(spree_sandbox_app_path))
          puts "Creating new Rails sandbox for Spree : #{spree_sandbox_app_path}"
          Dir.chdir( File.expand_path( "#{spree_sandbox_app_path}/..") )
          system('rails new sandbox')
          Dir.chdir(spree_sandbox_app_path)
          system('spree install')
          
          if(DataShift::SpreeHelper::version >= 1.2)
            append_file ('Gemfile', "gem 'spree_auth_devise', :git => \"git://github.com/spree/spree_auth_devise\"" )
          end
          
        end
  
        puts "Using Rails sandbox for Spree : #{spree_sandbox_app_path}"
        
        run_in(spree_sandbox_app_path) {
                  
          begin
            require 'config/environment.rb'
          rescue => e
            #somethign in deface seems to blow up suddenly on 1.1
            puts "Warning - Potential issue initializing Spree sandbox:"
            puts e.backtrace
            puts "#{e.inspect}"
          end
        
          set_logger
        
        }
        
        @dslog.info "Booted Spree using version #{DataShift::SpreeHelper::version}"
      end
    end

    def self.boot_pre_1
 
      require 'rake'
      require 'rubygems/package_task'
      require 'thor/group'

      require 'spree_core/preferences/model_hooks'
      #
      # Initialize preference system
      ActiveRecord::Base.class_eval do
        include Spree::Preferences
        include Spree::Preferences::ModelHooks
      end
 
      gem 'paperclip'
      gem 'nested_set'

      require 'nested_set'
      require 'paperclip'
      require 'acts_as_list'

      CollectiveIdea::Acts::NestedSet::Railtie.extend_active_record
      ActiveRecord::Base.send(:include, Paperclip::Glue)

      gem 'activemerchant'
      require 'active_merchant'
      require 'active_merchant/billing/gateway'

      ActiveRecord::Base.send(:include, ActiveMerchant::Billing)
  
      require 'scopes'
    
      # Not sure how Rails manages this seems lots of circular dependencies so
      # keep trying stuff till no more errors
    
      Dir[lib_root + '/*.rb'].each do |r|
        begin
          require r if File.file?(r)  
        rescue => e
        end
      end

      Dir[lib_root + '/**/*.rb'].each do |r|
        begin
          require r if File.file?(r) && ! r.include?('testing')  && ! r.include?('generators')
        rescue => e
        end
      end
    
      load_models( true )

      Dir[lib_root + '/*.rb'].each do |r|
        begin
          require r if File.file?(r)  
        rescue => e
        end
      end

      Dir[lib_root + '/**/*.rb'].each do |r|
        begin
          require r if File.file?(r) && ! r.include?('testing')  && ! r.include?('generators')
        rescue => e
        end
      end

      #  require 'lib/product_filters'
     
      load_models( true )

    end
  
    def self.load_models( report_errors = nil )
      puts 'Loading Spree models from', root
      Dir[root + '/app/models/**/*.rb'].each {|r|
        begin
          require r if File.file?(r)
        rescue => e
          puts("WARNING failed to load #{r}", e.inspect) if(report_errors == true)
        end
      }
    end

    def self.migrate_up
      ActiveRecord::Migrator.up( File.join(root, 'db/migrate') )
    end
  end  # => module SpreeHelper
end