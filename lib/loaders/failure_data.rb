# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     May 2016
# License::   MIT
#
# Details::   Holds the current context and load object related to a failure
#
module DataShift

  class FailureData

    attr_accessor :load_object
    attr_accessor :node_context

    # The database object, and the inbound context that failed
    def initialize(load_object, node_context, error_messages = [])
      @load_object  = load_object
      @node_context = node_context

      @error_messages = error_messages
    end

    def errors
      (load_object.errors.full_messages + error_messages).uniq
    end

    def destroy_failed_object
      if load_object.respond_to?('destroy') && !load_object.new_record?
        load_object.destroy
        reset
      end if load_object
    end

  end
end
