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

require 'rubygems'

require 'rake'

lib = File.expand_path('../lib/', __FILE__)

$:.unshift '.' 
$:.unshift lib unless $:.include?(lib)

require 'datashift'

# Add in our own Tasks

desc 'Build gem and install in one step'
task :build, :version do |_t, args|

  v = (args[:version] || ENV['version'])

  # Bump the VERSION file in library
  File.open( File.join('VERSION'), 'w') do |f|
    f << "#{v}\n"
  end if v

  system("jruby -S gem build datashift.gemspec")
  #Rake::Task[:gem].invoke

  version = DataShift.gem_version
  puts "Installing version #{version}"
  
  gem = "#{DataShift.gem_name}-#{version}.gem"
  cmd = "gem install --no-ri --no-rdoc #{gem}"
  system(cmd)
end
  
# Long parameter lists so ensure rake -T produces nice wide output
ENV['RAKE_COLUMNS'] = '180'
