# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     March 2015
# License::   MIT
#
# Details::   Manage the current loader object
#

module DataShift

  class LoadObject < BasicObject

    attr_accessor :subject

    def initialize(current_object)
      @subject = current_object
    end

    # This method usually called during processing to avoid errors with associations like
    #   <ActiveRecord::RecordNotSaved: You cannot call create unless the parent is saved>
    # If the object is still invalid at this point probably indicates compulsory
    # columns on model have not been processed before associations on that model
    #
    def save_if_new
      return unless(@subject.new_record?)

      if(@subject.valid?)
        @subject.save
      else
        fail DataShift::SaveError.new("Cannot Save Invalid #{subject.class} Record : #{subject.errors.full_messages.inspect}")
      end
    end

    private

    def method_missing(method, *args, &block)
      @subject.send(method, *args, &block)
    end

  end

end
