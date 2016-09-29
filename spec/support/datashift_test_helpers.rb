# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::
# License::   MIT
#
module DataShift

  module TestHelpers

    def rspec_datashift_root
      @rspec_datashift_root ||= File.expand_path('../..', __FILE__)
    end

    def run_in(dir)
      puts "RSpec .. switching context to run tests in path [#{dir}]"
      original_dir = Dir.pwd
      begin
        Dir.chdir dir
        yield
      ensure
        Dir.chdir original_dir
      end
    end

    def capture_stream(stream)
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

    # PATHS

    def rails_sandbox_path
      DataShift::Sandbox.rails_sandbox_path
    end

    def fixtures_path
      File.join(rspec_datashift_root, 'fixtures')
    end

    def ifixture_file( name )
      File.join(fixtures_path, name)
    end

    def results_path
      File.join(fixtures_path, 'results')
    end

    def datashift_thor_root
      @datashift_thor_root ||= File.expand_path('../../../lib/tasks', __FILE__)
    end

    # Return location of an expected results file and ensure tree clean before test
    def result_file( name )
      expect = File.join(results_path, name)

      begin FileUtils.rm(expect); rescue; end

      expect
    end

    def clear_everything
      DataShift::Configuration.reset

      results_clear
      db_clear
    end

    # These are our test models with associations
    def db_clear
      [Project, Milestone, Category, Version, LoaderRelease].each(&:delete_all)
    end


    def results_clear( glob = nil )
      if glob
        begin FileUtils.rm_rf( File.join(results_path, glob) ); rescue; end
      else
        begin FileUtils.rm_rf(results_path); rescue; end

        FileUtils.mkdir(results_path) unless File.exist?(results_path)
      end
    end

    def bundler_setup(gemfile = File.join(DataShift.root_path, 'spec', 'Gemfile') )

      $stderr.puts "No Such Gemfile #{gemfile}" unless File.exist?(gemfile)

      ENV['BUNDLE_GEMFILE'] = gemfile
      # Bundler.setup
      begin
        # Bundler.setup(:default, :development)
        Bundler.setup(:default, :test)
      rescue Bundler::BundlerError => e
        $stderr.puts e.message
        $stderr.puts 'Run `bundle install` to install missing gems'
        exit e.status_code
      end
    end

    def db_clear_connections
      # We have multiple schemas and hence connections tested in single spec directory
      ActiveRecord::Base.clear_active_connections!
    end

    def database_yml_path
      File.join(fixtures_path, 'config', 'database.yml')
    end

    def db_connect( env = 'test_file')

      # Some active record stuff seems to rely on the RAILS_ENV being set ?

      ENV['RAILS_ENV'] = env

      puts "Load DB Config for Env : #{env}"

      # We have multiple schemas and hence connections tested in single spec directory
      db_clear_connections

      configuration = {}

      configuration[:database_configuration] = YAML.load( ERB.new( IO.read(database_yml_path) ).result )
      db = configuration[:database_configuration][env]

      set_logger

      puts 'Connecting to DB', db.inspect

      ActiveRecord::Base.establish_connection( db )
    end

    def load_in_memory
      load "#{Rails.root}/db/schema.rb"
    end

    def migrate_up( _rails_root = fixtures_path )
      p = File.join(fixtures_path, 'db/migrate')
      raise "Cannot migrate DB - no such path #{p}" unless File.exist?(p)
      ActiveRecord::Migrator.up(p)
    end


  end

end
