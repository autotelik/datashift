# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Dec 2012
# License::   MIT
#
# Details::   Store and report stats
#
module DataShift


  class Reporter

    include DataShift::Logging

    # actual data rows/objects inbound
    attr_accessor :processed_object_count
    alias_method :processed_inbound_count, :processed_object_count

    # DB objects created, updated etc
    attr_accessor :loaded_objects, :failed_objects

    # actual data rows/objects inbound
    attr_accessor :success_inbound_count, :failed_inbound_count

    def initialize()
      reset
    end

    def reset()
      @processed_object_count = 0
      @loaded_objects, @failed_objects = [], []
      @success_inbound_count, @failed_inbound_count = 0,0
    end

    def add_loaded_object(object)
      @loaded_objects << object.id unless(object.nil? || @loaded_objects.include?(object))
    end
    
    def add_failed_object(object)
      @failed_objects << object unless( object.nil? || @failed_objects.include?(object))
    end
    
    def report
      loaded_objects.compact! if(loaded_objects)
      
      puts "\nProcessing Summary Report"
      puts ">>>>>>>>>>>>>>>>>>>>>>>>>\n"
      puts "Processed total of #{processed_object_count} inbound #{processed_object_count > 1 ? 'entries' : 'entry'}"
      puts "#{loaded_objects.size}\tdatabase objects were successfully processed."
      puts "#{success_inbound_count}\tinbound rows were successfully processed."

      puts "There were NO failures." if failed_objects.empty?
        
      puts "WARNING : Check logs : #{failed_objects.size} rows contained errors" unless failed_objects.empty?
    end
    
  end
end