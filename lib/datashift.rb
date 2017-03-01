# Copyright:: (c) Autotelik Media Ltd 2010 - 2015 Tom Statter
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   Free, Open Source.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
require 'forwardable'

require_relative 'datashift/guards'
require_relative 'datashift/logging'

require 'active_record'
require 'active_support/core_ext/module/delegation'

module DataShift

  def self.gem_name
    'datashift'
  end

  def self.root_path
    File.expand_path("#{File.dirname(__FILE__)}/..")
  end

  def self.library_path
    File.expand_path("#{File.dirname(__FILE__)}/../lib")
  end

  def self.require_libraries

    loader_libs = %w(lib)

    # Base search paths - these will be searched recursively
    loader_paths = []

    loader_libs.each { |l| loader_paths << File.join(root_path, l) }

    # Define require search paths, any dir in here will be added to LOAD_PATH

    loader_paths.each do |base|
      $LOAD_PATH.unshift base if File.directory?(base)
      Dir[File.join(base, '**', '**')].each do |p|
        $LOAD_PATH.unshift p if File.directory?(p)
      end
    end

    begin
      require_relative 'datashift/delimiters'
      require_relative 'datashift/load_object'
      require_relative 'datashift/generators/generator_base'
      require_relative 'datashift/loaders/reporters/reporter'
      require_relative 'datashift/loaders/loader_base'
      require_relative 'datashift/exporters/exporter_base'
    rescue => x
      puts "Problem initializing gem #{x.inspect}"
    end

    require_libs = %w(
      datashift/core_ext
      datashift
      datashift/mapping
      datashift/model_methods
      datashift/transformation
      datashift/inbound_data
      datashift/loaders
      datashift/loaders/reporters
      datashift/exporters
      datashift/generators
      datashift/helpers
      datashift/applications
      datashift/populators
    )

    require_libs.each do |base|
      Dir[File.join(library_path, base, '*.rb')].each do |rb|
        # puts rb
        begin
          require_relative rb unless File.directory?(rb)
        rescue => x
          puts "Problem loading datashift file #{rb} - #{x.inspect}"
        end
      end
    end

    if(DataShift::Guards.jruby?)
      require 'jexcel_file'
      JExcelFile
    else
      require 'spreadsheet'
      require 'spreadsheet_extensions'
      Spreadsheet
    end

  end

  # Load all the datashift  tasks and make them available throughout app
  def self.load_tasks
    # Long parameter lists so ensure rake -T produces nice wide output
    ENV['RAKE_COLUMNS'] = '180'
    base = File.join(root_path, 'tasks', '**')
    Dir["#{base}/*.rake"].sort.each { |ext| load ext }
  end

  # Load all public datashift Thor commands and make them available throughout app

  def self.load_commands
    base = File.join(library_path, 'tasks')

    Dir["#{base}/*.thor"].each do |f|
      next unless File.file?(f)
      load(f)
    end
  end

end

DataShift.require_libraries

module DataShift
  if Guards.jruby?
    require 'java'

    class Object
      def add_to_classpath(path)
        $CLASSPATH << File.join( DataShift.root_path, 'lib', path.tr('\\', '/') )
      end
    end
  end
end
