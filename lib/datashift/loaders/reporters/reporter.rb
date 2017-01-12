# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Base class for reporters on loading stats
#
module DataShift
  module Reporters
    class Reporter

      include DataShift::Logging

      # Holds the actual data r.e data rows/objects inbound
      attr_accessor :progress_monitor

      def initialize(progress_monitor = DataShift::ProgressMonitor.new)
        @progress_monitor = progress_monitor
      end

      # an abstract method
      def report; end

    end
  end
end
