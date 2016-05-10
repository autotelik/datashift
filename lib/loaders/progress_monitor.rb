# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Dec 2016
# License::   MIT
#
# Details::   Store and report stats on the current load
#
module DataShift

  class ProgressMonitor

    include DataShift::Logging

    # actual data rows/objects inbound
    attr_accessor :processed_object_count
    alias processed_inbound_count processed_object_count

    # DB objects created, updated etc
    attr_accessor :loaded_objects, :failed_objects

    # actual data rows/objects inbound
    attr_accessor :success_inbound_count, :failed_inbound_count

    def initialize
      reset
    end

    def reset
      @processed_object_count = 0
      @loaded_objects = []
      @failed_objects = []

      @success_inbound_count = 0
      @failed_inbound_count = 0
    end

    def success(reportable_object)
      add_loaded_object(reportable_object)
    end

    # Loading failed. Store a failed object and if requested roll back (destroy) the current load object
    # For use case where object saved early but subsequent required columns fail to process
    # so the load object is invalid

    def failure(failure_data, error_messages = [])

      logger.error "Failure(S) reported : #{[*error_messages].inspect}" unless error_messages.empty?

      add_failed_object(failure_data)

      failure_data.destroy_failed_object if(DataShift::Importers::Configuration.call.destroy_on_failure)
    end


    def add_loaded_object(object)
      @success_inbound_count += 1
      @processed_object_count += 1

      @loaded_objects << object.id unless object.nil? || @loaded_objects.include?(object)
    end

    def add_failed_object(object)
      @failed_inbound_count += 1
      @processed_object_count += 1

      @failed_objects << object unless  object.nil? || @failed_objects.include?(object)
    end

  end
end
