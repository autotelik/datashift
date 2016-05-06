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
