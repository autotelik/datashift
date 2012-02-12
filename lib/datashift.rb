# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   TBD. Free, Open Source. MIT ?
#
# Details::   Active Record Loader
#
require 'rbconfig'
  
module DataShift

  module Guards

    def self.jruby?
      return RUBY_PLATFORM == "java"
    end
    def self.mac?
      RbConfig::CONFIG['target_os'] =~ /darwin/i
    end

    def self.linux?
      RbConfig::CONFIG['target_os'] =~ /linux/i
    end

    def self.windows?
      RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    end

  end

  if(Guards::jruby?)
    require 'java'
      
    class Object
      def add_to_classpath(path)
        $CLASSPATH << File.join( DataShift.root_path, 'lib', path.gsub("\\", "/") )
      end
    end
  end

  def self.gem_version
    unless(@gem_version)
      if(File.exists?('VERSION'))
        File.read( File.join('VERSION') ).match(/.*(\d+.\d+.\d+)/)
        @gem_version = $1
      else
        @gem_version = '1.0.0'
      end
    end
    @gem_version
  end

  def self.gem_name
    "datashift"
  end

  def self.root_path
    File.expand_path("#{File.dirname(__FILE__)}/..")
  end

  def self.library_path
    File.expand_path("#{File.dirname(__FILE__)}/../lib")
  end
  
  def self.require_libraries
    
    loader_libs = %w{ lib  }

    # Base search paths - these will be searched recursively
    loader_paths = []

    loader_libs.each {|l| loader_paths << File.join(root_path(), l) }

    # Define require search paths, any dir in here will be added to LOAD_PATH

    loader_paths.each do |base|
      $:.unshift base  if File.directory?(base)
      Dir[File.join(base, '**', '**')].each do |p|
        if File.directory? p
          $:.unshift p
        end
      end
    end
    
    require_libs = %w{ datashift loaders helpers }

    require_libs.each do |base|
      Dir[File.join(library_path, base, '*.rb')].each do |rb|
        unless File.directory? rb
          require rb
        end
      end
    end

  end

  def self.load_tasks
    # Long parameter lists so ensure rake -T produces nice wide output
    ENV['RAKE_COLUMNS'] = '180'
    base = File.join(root_path, 'tasks', '**')
    Dir["#{base}/*.rake"].sort.each { |ext| load ext }
  end

  
  module Logging
    
    class MultiIO
           
      def initialize(*targets)
        @targets = []
        targets.each {|t| @targets << Logger.new(t) }
      end

      def add(target)
        @targets << Logger.new(target)
      end
      
      
      def method_missing(method, *args, &block)
        @targets.each {|t| t.send(method, *args, &block) }
      end
    
      def verbose
        puts 'add a target to stdout'
        add(STDOUT)
      end
    
    end
    
    require 'logger'
     
    def logdir
      @logdir ||= 'log'
      @logdir
    end
  
    def logger
      @logger ||= open
      @logger
    end
    
    private
    
    def open( log = 'datashift.log')
      FileUtils::mkdir(logdir) unless File.directory?(logdir)
      log_file = File.open( File.join(logdir(), 'datashift.log'), "a")
      @logger = MultiIO.new(log_file)
      @logger
    end
  end
  
end

DataShift::require_libraries