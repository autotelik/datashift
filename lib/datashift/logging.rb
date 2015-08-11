# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Aug 2012
# License::   Free, Open Source. MIT.
#
# Details::   Logging facilities for datashift.
#
require 'fileutils'

module DataShift

  module Logging

    class MultiIO

      def initialize(*targets)
        @targets = []
        targets.each { |t| @targets << Logger.new(t) }
      end

      def add(target)
        @targets << Logger.new(target)
      end

      def method_missing(method, *args, &block)
        @targets.each { |t| t.send(method, *args, &block) }
      end

      def verbose
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

      FileUtils.mkdir(logdir) unless File.directory?(logdir)

      logname = File.join(logdir, log)

      log_file = File.open(logname, 'a')

      puts "Opened datashift log @ #{logname}"

      multi_logger = MultiIO.new(log_file)

      #return ActiveRecord::Base.logger if(defined?(ActiveRecord) && ActiveRecord::Base.logger)
      ActiveRecord::Base.logger = multi_logger if(defined?(ActiveRecord) && ActiveRecord::Base.logger)

    end
  end

end
