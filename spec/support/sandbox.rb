require_relative "datashift_test_helpers"

module DataShift

  class Sandbox

    include DataShift::TestHelpers
    extend DataShift::TestHelpers

    def self.sandbox_gem_list
      add_gem 'datashift', path:  File.expand_path('../../..', __FILE__)
      add_gem 'factory_bot_rails'
      add_gem 'ffaker'
    end

    def self.rails_sandbox_name
      'dummy'
    end

    def self.rails_sandbox_parent
      @rails_sandbox_parent ||= File.expand_path('../..', __FILE__)
    end

    def self.rails_sandbox_path
      File.join(rails_sandbox_parent, rails_sandbox_name)
    end

    def self.rails_sandbox_gemfile
      File.join(rails_sandbox_path, 'Gemfile')
    end

    def self.rails_sandbox_spec_path
      @rails_sandbox_spec_path ||= File.join(rails_sandbox_path, 'spec')
      FileUtils.mkdir_p(@rails_sandbox_spec_path) unless File.exists?(@rails_sandbox_spec_path)
      @rails_sandbox_spec_path
    end

    def self.gen_rails_sandbox( force = false)

      sandbox = rails_sandbox_path

      puts "RSPEC - checking for Rails sandbox [#{sandbox}]"

      if((force == true || force == :force) && File.exist?(sandbox))
        puts "Rails SANDBOX [#{sandbox}] exists - ** DELETING **"
        FileUtils.rm_rf(sandbox)
      end

      if File.exist?(sandbox)
        puts "RSPEC - Found and using existing Rails sandbox [#{sandbox}]"
      else

        puts "RSPEC SANDBOX - Creating sandbox in : #{rails_sandbox_parent}"

        rails_new_opts = ' --skip-bundle --skip-action-mailer --quiet --skip-test '
        cmd = "rails new #{rails_sandbox_name} #{rails_new_opts}"

        run_in( rails_sandbox_parent ) do
          puts "RSPEC SANDBOX - Creating new Rails app : #{cmd}"
          system(cmd)
          puts "RSPEC SANDBOX - Sandbox created with Rails VERSION : #{system('rails -v')}"
        end

        puts 'RSPEC SANDBOX - Configuring gems in Gemfile'
        run_in(rails_sandbox_path) do
          sandbox_gem_list

          puts "Running bundle install for [#{rails_sandbox_gemfile}]"
          Bundler.with_clean_env { system("bundle install  --gemfile #{rails_sandbox_gemfile}") }
        end

        setup_db_install
      end

      # Copy over the latest versions to pick up any local development during testing
      run_in( rails_sandbox_parent ) do
        puts "RSPEC SANDBOX - Manually copying models, factories etc from #{fixtures_path}"
        src = File.join(rails_sandbox_parent, 'factories')
        dest = File.join(rails_sandbox_spec_path, 'factories')
        FileUtils.rm_rf(dest) if File.exist?(dest)
        FileUtils.copy_entry(src, dest)

        FileUtils.cp_r( Dir.glob(File.join(fixtures_path, 'models', '*.rb')), File.join(rails_sandbox_path, 'app/models'))

        FileUtils.cp_r( File.join(fixtures_path, 'sandbox_example.thor'), rails_sandbox_path)
      end

      File.open(File.join(rails_sandbox_path, 'config/initializers/mime_types.rb'), 'ab') do |file|
        file.write("Mime::Type.register 'application/xls', :xls\n")
      end

      puts "RSPEC SANDBOX - Build Complete"
      sandbox
    end

    def self.run_in(dir)
      puts "RSPEC SANDBOX - Switching context to run in [#{dir}]"
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

        puts 'RSPEC SANDBOX - Creating DB'
        system('bundle exec rake db:create')

        # SCAFFOLD THE TEST MODELS
        puts 'RSPEC SANDBOX - Scaffold the Test Models'

        # TODO - Move the columns from fixtures_path migration to the scaffolds and auto generate migration
        scaffold_opts = " -f -q --no-migration --no-stylesheets --no-assets "
        Dir.glob(File.join(fixtures_path, 'models', '*.rb')).each do |m|
          cmd = "RAILS_ENV=development bundle exec rails g scaffold #{File.basename(m, '.*')} #{scaffold_opts}"
          puts cmd
          system(cmd)
        end

        # TODO - Move this to scaffolding above
        puts 'Creating Migrations and Seed Data'
        migrations = File.expand_path(File.join(fixtures_path, 'db', 'migrate'), __FILE__)
        FileUtils.cp_r( migrations, File.join(rails_sandbox_path, 'db'))

        seeds = File.expand_path(File.join(fixtures_path, 'db', 'seeds.rb'), __FILE__)
        FileUtils.cp_r( seeds, File.join(rails_sandbox_path, 'db'))

        puts 'Running db:migrate'
        system('bundle exec rake db:migrate RAILS_ENV=development')
        system('bundle exec rake db:migrate RAILS_ENV=test')
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
