# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Very basic report to dump out loading report stats
#
module DataShift
  module Reporters
    class BasicStdoutReporter < Reporter

      def initialize(progress_monitor)
        super progress_monitor
      end

      def report
        loaded_objects = progress_monitor.loaded_objects

        loaded_objects.compact! if loaded_objects

        inbound_str = progress_monitor.processed_object_count > 1 ? 'entries' : 'entry'

        puts "\nProcessing Summary Report"
        puts ">>>>>>>>>>>>>>>>>>>>>>>>>\n"
        puts "Processed total of #{progress_monitor.processed_object_count} inbound #{inbound_str}"
        puts "#{loaded_objects.size}\tdatabase objects were successfully processed."
        puts "#{progress_monitor.success_inbound_count}\tinbound rows were successfully processed."

        failed_inbound_count = progress_monitor.failed_inbound_count

        if failed_inbound_count == 0
          puts 'There were NO failures.'
        else
          puts "WARNING : There were Failures - Check logs\n#{failed_inbound_count} rows contained errors"
          puts "#{progress_monitor.failed_objects.size} objects could not be saved to DB"
        end
      end

    end
  end
end
