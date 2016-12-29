# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
#
# License::   MIT - Free, OpenSource
#
# Details::   Gem::Specification for DataShift gem.
#
#             Provides classes for moving data between a number of enterprise
#             type applications, files and databases.
#
#             Provides support for moving data between .xls (Excel/OpenOffice)
#             Spreedsheets via Ruby and AR, enabling direct import/export of 
#             ActiveRecord models with all their associations from database.
#
#             Provides support for moving data between csv files and AR, enabling direct
#             import/export of AR models and their associations from database.
#
require 'thor'

$:.push File.expand_path("lib", __FILE__)

require 'datashift'
require 'factory_girl_rails'
require 'database_cleaner'

require_relative File.join('spec', 'support/sandbox')
require_relative File.join('spec' ,'support/datashift_test_helpers')

module Datashift

  class Utils < Thor

    include DataShift::TestHelpers

    desc "lint", "Run in spec - Verify that FactoryGirl factories are valid"

    def lint

      ENV['RAILS_ENV'] = 'test'

      environment

      begin
        DatabaseCleaner.start

        puts "Running FactoryGirl.lint"
        FactoryGirl.lint
      ensure
        DatabaseCleaner.clean
      end

    end


    desc "sandbox", 'Rebuild the dummy rails app in spec - required for testing'

    def sandbox
      # Need an active record DB to test against, so we manage own Rails sandbox
      DataShift::Sandbox.gen_rails_sandbox( :force )
    end

    desc "build", 'Build gem and install in one step'

    method_option :version, :aliases => '-v',  :desc => "New version", required: false

    method_option :push, :aliases => '-p', :desc => "Push resulting gem to rubygems.org"

    method_option :install, :aliases => '-i',
                  :desc => "Install freshly built gem locally", type: :boolean, default: false

    def build

      version = options[:version] || DataShift::VERSION

      # Bump the VERSION file in library
      File.open( File.join('lib/datashift/version_factory.rb'), 'w') do |f|
        f << "module DataShift\n"
        f << "    VERSION = '#{version}'.freeze\n"
        f << "end\n"
      end if(options[:version] != DataShift::VERSION)

      build_cmd =  "gem build datashift.gemspec"

      puts "\n*** Running build cmd [#{build_cmd}]"

      system(build_cmd)

      gem = "#{DataShift.gem_name}-#{version}.gem"

      if(options[:install])
        puts "Installing : #{gem}"

        cmd = "gem install --no-ri --no-rdoc #{gem}"
        system(cmd)
      end

      if(options[:push])
        puts "Pushing version #{version} to rubygems"
        cmd = "gem push #{gem}"
        system(cmd)
      end
    end

    no_commands do
      def environment

        env = File.expand_path('dummy/config/environment.rb')

        if File.exist?(env)
          begin
            require env
          rescue => e
            logger.error("Failed to initialise ActiveRecord : #{e.message}")
            raise ConnectionError.new("Failed to initialise ActiveRecord : #{e.message}")
          end

        else
          raise DataShift::PathError.new('No config/environment.rb found - cannot initialise ActiveRecord')
        end
      end
    end

  end
end
