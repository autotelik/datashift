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

require 'lib/datashift'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = DataShift.gem_name
  gem.homepage = "http://github.com/autotelik/datashift"
  gem.license = "MIT"
  gem.summary = %Q{ Shift data betwen Excel/CSV and any Ruby app}
  gem.description = %Q{Comprehensive tools to import/export between Excel/CSV and ActiveRecord databases, Rails apps, and any Ruby project.}
  gem.email = "rubygems@autotelik.co.uk"
  gem.authors = ["Thomas Statter"]
  # dependencies defined in Gemfile
  gem.files.exclude ['sandbox']
  
  gem.add_dependency 'spreadsheet'
  gem.add_dependency 'rubyzip'
  
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "DataShift #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# Add in our own Tasks

desc 'Build gem and install in one step'
task :build, :version do |t, args|

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
  cmd = "jruby -S gem install --no-ri --no-rdoc #{gem}"
  system(cmd)
end
  
# Long parameter lists so ensure rake -T produces nice wide output
ENV['RAKE_COLUMNS'] = '180'
