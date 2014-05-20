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

lib = File.expand_path('../lib/', __FILE__)

$:.unshift '.' 
$:.unshift lib unless $:.include?(lib)

require 'datashift'

class Datashift < Thor

  desc "build", 'Build gem and install in one step'

  method_option :version, :aliases => '-v',  :desc => "New version"
  method_option :push, :aliases => '-p', :desc => "Push resulting gem to rubygems.org"
 

  def build

    v = options[:version] 

    # Bump the VERSION file in library
    File.open( File.join('VERSION'), 'w') do |f|
      f << "#{v}\n"
    end if v
    
    build_cmd =  "gem build datashift.gemspec"

    puts "\n*** Running build cmd [#{build_cmd}]"
    
    system(build_cmd)

    version = DataShift.gem_version
    puts "Installing version #{version}"
  
    gem = "#{DataShift.gem_name}-#{version}.gem"
    cmd = "gem install --no-ri --no-rdoc #{gem}"
    system(cmd)
    
    if(options[:push])
      cmd = "gem push #{gem}"
      system(cmd)
    end
  end

end
