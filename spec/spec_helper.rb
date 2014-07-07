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
require 'paperclip'

$:.unshift '.'  # 1.9.3 quite strict, '.' must be in load path for relative paths to work from here
    
datashift_spec_base = File.expand_path( File.join(File.dirname(__FILE__), '..') )

require File.join(datashift_spec_base, 'lib/datashift')


RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  shared_context "ActiveRecordTestModelsConnected" do
    
    before(:all) do
      bundler_setup()
    
      # load all test model definitions - Project etc  
      require ifixture_file('test_model_defs')  
  
      db_connect( 'test_file' )    # , test_memory, test_mysql

      migrate_up
    end
  end
  
  
  shared_context "ClearAndPopulateProject" do
  
    before(:each) do
      
      Project.delete_all
      Owner.delete_all
      
      DataShift::MethodDictionary.clear
    
      DataShift::MethodDictionary.find_operators( Project )
    
      DataShift::MethodDictionary.build_method_details( Project )
    
      DataShift::MethodDictionary.for?(Project).should == true
    end
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
  
  def fixtures_path()
    File.expand_path(File.dirname(__FILE__) + '/fixtures')
  end
  
  def ifixture_file( name )
    File.join(fixtures_path(), name)
  end
  
  def results_path
    File.join(fixtures_path(), 'results')
  end
   
  # Return location of an expected results file and ensure tree clean before test
  def result_file( name )
    expect = File.join(results_path, name)

    begin FileUtils.rm(expect); rescue; end

    expect
  end
  
  def results_clear
    begin FileUtils.rm_rf(results_path); rescue; end
    
    FileUtils.mkdir(results_path) unless File.exists?(results_path);
  end
  
  def set_logger( name = 'datashift_spec.log')
    
    require 'logger'
    logdir = File.join(File.dirname(__FILE__), 'log')
    FileUtils.mkdir_p(logdir) unless File.exists?(logdir)
    ActiveRecord::Base.logger = Logger.new( File.join(logdir, name) )
  end
  
  def bundler_setup(gemfile = File.join(DataShift::root_path, 'spec', 'Gemfile') )
    
    $stderr.puts "No Such Gemfile #{gemfile}" unless File.exists?(gemfile)
    
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
  
  def database_yml_path
    File.join(fixtures_path, 'config', 'database.yml')
  end
  
  def db_connect( env = 'test_file')
 
    # Some active record stuff seems to rely on the RAILS_ENV being set ?

    ENV['RAILS_ENV'] = env
 
    # We have multiple schemas and hence connections tested in single spec directory   
    db_clear_connections
     
    configuration = {}
    
    configuration[:database_configuration] = YAML::load( ERB.new( IO.read(database_yml_path) ).result )
    db = configuration[:database_configuration][ env ]

    puts "Setting DB Config:", db.inspect
    ActiveRecord::Base.configurations = db
    
    set_logger
    
    puts "Connecting to DB"
    
    ActiveRecord::Base.establish_connection( db )
  end
  
  # These are our test models with associations
  def db_clear
    [Project, Milestone, Category, Version, LoaderRelease].each {|x| x.delete_all}
  end

  def load_in_memory
    load "#{Rails.root}/db/schema.rb"
  end

  def migrate_up( rails_root = fixtures_path )
    p = File.join(fixtures_path, 'db/migrate')
    raise "Cannot migrate DB - no such path #{p}" unless File.exists?(p)
    ActiveRecord::Migrator.up(p)
  end

  def rails_sandbox_path
    File.expand_path('../../spec/rails_sandbox', __FILE__)
  end

  def rails_sandbox( force = false)
    
    rails_sandbox = rails_sandbox_path
     
    if(force == true && File.exists?(rails_sandbox))
      FileUtils::rm_rf(rails_sandbox)
    end
    
    unless(File.exists?(rails_sandbox))
      
      puts "Creating new Rails sandbox : ", File.expand_path( "#{rails_sandbox}/.." )
    
      run_in( File.expand_path("#{rails_sandbox}/..") ) do |path|
          
        name = File.basename(DataShift::sandbox)
      
        puts "Creating new Rails sandbox in : #{path}"
        system('rails new ' + name)
          
        puts "Copying over models :", Dir.glob(File.join(fixtures_path, 'models', '*.rb')).inspect
        
        FileUtils::cp_r( Dir.glob(File.join(fixtures_path, 'models', '*.rb')), File.join(name, 'app/models'))
        
        migrations = File.expand_path('../../spec/db/migrate', __FILE__)
        
        FileUtils::cp_r( migrations, File.join(rails_sandbox, 'db'))
        
        puts "Running db:migrate"
        
        run_in(rails_sandbox) { system('bundle exec rake db:migrate') }
      end
    end
    rails_sandbox
  end
  
end