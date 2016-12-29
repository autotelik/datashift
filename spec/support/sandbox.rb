require_relative "datashift_test_helpers"

module DataShift

  class Sandbox

    include DataShift::TestHelpers
    extend DataShift::TestHelpers

    def self.sandbox_gem_list
      add_gem 'datashift', path:  File.expand_path('../../..', __FILE__)
      add_gem 'awesome_print'
      add_gem 'factory_girl_rails'
    end

    def self.rails_sandbox_path
      File.expand_path('../../dummy', __FILE__)
    end

    def self.gen_rails_sandbox( force = false)

      sandbox = rails_sandbox_path

      puts "RSPEC - checking for Rails sandbox [#{sandbox}]"

      if((force == true || force == :force) && File.exist?(sandbox))
        puts "Rails SANDBOX [#{sandbox}] exists - ** DELETING **"
        FileUtils.rm_rf(sandbox)
      end

      sandbox_parent_dir =  File.expand_path( "#{sandbox}/.." )

      if File.exist?(sandbox)
        puts "RSPEC - Found and using existing Rails sandbox [#{sandbox}]"
      else

        puts "RSPEC SANDBOX - Creating new Rails sandbox in : #{sandbox_parent_dir}"

        run_in( sandbox_parent_dir ) do
          puts "RSPEC DUMMY - Sandbox created with Rails VERSION : #{system('rails -v')}"
          system('rails new ' + File.basename(rails_sandbox_path))
        end

        puts "RSPEC SANDBOX - Configuring gems and DB in rails sandbox Gemfile"

        run_in(rails_sandbox_path) do
          sandbox_gem_list
          system("cat #{File.join(rails_sandbox_path, 'Gemfile')}")

          migrations = File.expand_path(File.join(fixtures_path, 'db', 'migrate'), __FILE__)
          FileUtils.cp_r( migrations, File.join(rails_sandbox_path, 'db'))

          seeds = File.expand_path(File.join(fixtures_path, 'db', 'seeds.rb'), __FILE__)
          FileUtils.cp_r( seeds, File.join(rails_sandbox_path, 'db'))
        end

        setup_db_install
      end

      # Copy over the latest versions to pick up any local development during testing
      run_in( sandbox_parent_dir ) do
        name = File.basename(rails_sandbox_path)

        puts "RSPEC DUMMY - Copying models from #{Dir.glob(File.join(fixtures_path, 'models'))}"

        FileUtils.cp_r( Dir.glob(File.join(fixtures_path, 'models', '*.rb')), File.join(name, 'app/models'))

        FileUtils.cp_r( File.join(fixtures_path, 'sandbox_example.thor'), rails_sandbox_path)
      end

      puts "RSPEC DUMMY - Build Complete"

      sandbox
    end

    def self.run_in(dir)
      puts "Sandbox .. switching context to run tests in path [#{dir}]"
      original_dir = Dir.pwd
      begin
        Dir.chdir dir
        yield
      ensure
        Dir.chdir original_dir
      end
    end

    def self.setup_db_install

      run_in(rails_sandbox_path) do
        puts "Running bundle install for [#{File.join(rails_sandbox_path, 'Gemfile')}]"

        Bundler.with_clean_env do
          system("bundle install  --gemfile #{File.join(rails_sandbox_path, 'Gemfile')}")
        end

        puts 'Creating and migrating DB'

        system('bundle exec rake db:create')

        puts 'Running db:migrate'

        system('RAILS_ENV=development bundle exec rake db:migrate')
        system('RAILS_ENV=test bundle exec rake db:migrate')

        threads = []

        Dir.glob(File.join(fixtures_path, 'models', '*.rb')).each do |m|
          threads << Thread.new { system("RAILS_ENV=development bundle exec rails g scaffold #{File.basename(m, '.*')}") }

          threads << Thread.new { system("RAILS_ENV=development bundle exec rails g resource_route #{File.basename(m, '.*')}") }
        end

        threads.each(&:join)

        system('bundle install')
      end

    end

    def self.add_gem(name, gem_options = {})

      puts "Append Gemfile with #{name}"
      parts = ["'#{name}'"]
      parts << ["'#{gem_options.delete(:version)}'"] if gem_options[:version]
      gem_options.each { |key, value| parts << "#{key}: '#{value}'" }

      File.open('Gemfile', 'ab') do |file|
        file.write( "\ngem #{parts.join(', ')}\n")
      end

    end

  end
end
