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
## encoding: utf-8

require 'thor'

$:.push File.expand_path("lib", __FILE__)

require 'datashift'

module Datashift

  class Utils < Thor

    desc "build", 'Build gem and install in one step'

    method_option :version, :aliases => '-v',  :desc => "New version"
    method_option :push, :aliases => '-p', :desc => "Push resulting gem to rubygems.org"
    method_option :install, :aliases => '-i', :desc => "Install freshly built gem locally"

    def build

      # Bump the VERSION file in library
      File.open( File.join('lib/datashift/version.rb'), 'w') do |f|
        f << "#{v}\n"
      end if(options[:version])

      load "datashift/version.rb"

      v = DataShift::VERSION

      build_cmd =  "gem build datashift.gemspec"

      puts "\n*** Running build cmd [#{build_cmd}]"

      system(build_cmd)

      puts "Installing version #{v}"

      if(options[:install])
        gem = "#{DataShift.gem_name}-#{v}.gem"
        cmd = "gem install --no-ri --no-rdoc #{gem}"
        system(cmd)
      end

      if(options[:push])
        cmd = "gem push #{gem}"
        system(cmd)
      end
    end

  end
end
