# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     March 2015
# License::   MI
#
# Details::   Manage the current loader object
#
#
module DataShift

  class LoadObject < SimpleDelegator

    attr_accessor :instance

    def initialize(current_object)
      super
      @instance = current_object
    end

    # delegate :errors, to: :instance

    # This method usually called during processing to avoid errors with associations like
    #   <ActiveRecord::RecordNotSaved: You cannot call create unless the parent is saved>
    # If the object is still invalid at this point probably indicates compulsory
    # columns on model have not been processed before associations on that model
    #
    def save_if_new
      return false unless instance && instance.new_record?

      return instance.save if instance.valid?

      raise SaveError, "Cannot Save #{instance.class} : #{instance.errors.full_messages.inspect}"
    end

    private

=begin
    def method_missing(method, *args, &block)
      raise "Cannot call [#{method}] on : #{instance.class.name}"
      if instance.respond_to? method
        instance.send(method, *args, &block)
      else
        raise "Cannot call [#{method}] on : #{instance.class.name}"
      end
    end
=end

  end

end
