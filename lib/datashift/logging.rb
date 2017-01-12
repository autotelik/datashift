# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2012
# License::   Free, Open Source. MIT.
#
# Details::   Logging facilities for datashift.
#
require 'fileutils'
require 'singleton'

module DataShift

  module Logging

    class MultiIO

      include Singleton

      attr_reader :targets

      def initialize
        @targets = []
        @names = []
      end

      def add_file(target)
        unless @names.include?(target)
          puts "Logging going to target [#{target}]"
          add( File.open(target, 'a') )
          @names << target
        end
      end

      def verbose
        target = 'stdout'
        unless @names.include?(target)
          add(STDOUT)
          @names << target
        end
      end

      def method_missing(method, *args, &block)
        @targets.each { |t| t.send(method, *args, &block) }
      end

      private

      def add(target)
        @targets << Logger.new(target)
      end

    end

    require 'logger'

    def logdir=(x)
      @logdir = x
    end

    def logdir
      @logdir ||= 'log'
      @logdir
    end

    def logger
      @mutli_logger ||= open
      @mutli_logger
    end

    def verbose
      @verbose_logger ||= logger.verbose
    end

    private

    def open( log = 'datashift.log')
      FileUtils.mkdir(logdir) unless File.directory?(logdir)

      MultiIO.instance.add_file(File.join(logdir, log))

      ActiveRecord::Base.logger = MultiIO.instance if defined?(ActiveRecord) && ActiveRecord::Base.logger

      MultiIO.instance.verbose if(DataShift::Configuration.call.verbose)

      MultiIO.instance
    end
  end

end
