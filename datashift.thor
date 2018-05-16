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

$LOAD_PATH.push File.expand_path('lib')

require 'datashift'
require 'factory_bot_rails'
require 'database_cleaner'

require_relative File.join('spec', 'support/sandbox')
require_relative File.join('spec', 'support/datashift_test_helpers')

module Datashift

  class Utils < Thor

    include DataShift::TestHelpers

    desc 'lint', 'Run in spec - Verify that FactoryBot factories are valid'

    def lint

      ENV['RAILS_ENV'] = 'test'

      environment

      begin
        DatabaseCleaner.start

        puts 'Running FactoryBot.lint'
        FactoryBot.lint
      ensure
        DatabaseCleaner.clean
      end

    end

    desc 'sandbox', 'Rebuild the dummy rails app in spec - required for testing'

    def sandbox
      # Need an active record DB to test against, so we manage own Rails sandbox
      DataShift::Sandbox.gen_rails_sandbox( :force )
    end

    desc 'build', 'Build gem and install in one step'

    method_option :bump, aliases: '-b', type: :string, desc: 'Bump the version', required: false

    method_option :push, aliases: '-p', desc: 'Push resulting gem to rubygems.org'

    method_option :install, aliases: '-i',
                            desc: 'Install freshly built gem locally', type: :boolean, default: false

    def build

      if options[:push] && (options[:bump].blank? || options[:bump] !~ /^(\d+\.)?(\d+\.)?(\*|\d+)$/)
        puts 'ERROR: Please bump to a new numeric version to push to rubygems'
        exit(-1)
      end

      if options[:bump] && options[:bump] !~ /^(\d+\.)?(\d+\.)?(\*|\d+)$/
        puts 'ERROR: bump should be a valid numeric version in form x.x.x'
        exit(-1)
      end

      version = options[:bump] || DataShift::VERSION

      # Bump the VERSION file in library
      if options[:bump].present?
        File.open( File.join('lib/datashift/version.rb'), 'w') do |f|
          f << "module DataShift\n"
          f << "    VERSION = '#{version}'.freeze unless defined?(VERSION)\n"
          f << "end\n"
        end
      end

      build_cmd = 'gem build datashift.gemspec'

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
          rescue StandardError => e
            logger.error("Failed to initialise ActiveRecord : #{e.message}")
            raise ConnectionError, "Failed to initialise ActiveRecord : #{e.message}"
          end

        else
          raise DataShift::PathError, 'No config/environment.rb found - cannot initialise ActiveRecord'
        end
      end
    end

  end
end
