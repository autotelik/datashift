# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Holds the current context in relation to the Document we are dealing with
#

module DataShift

  class DocContext

    include DataShift::Logging

    attr_reader :klass

    attr_accessor :load_object, :current_row

    # The current Node
    attr_accessor :context

    # The inbound document headers
    attr_accessor :headers

    attr_accessor :reporter, :errors

    # Options :
    #    formatter
    #    populator
    #
    def initialize( klass )
      @klass = klass

      @headers  = DataShift::Headers.new(:na)
      @reporter = DataShift::Reporter.new

      @errors = []
    end

    def klass=( klass )
      @klass = klass
      reset
    end

    # Reset the database object to be populated
    #
    def reset(object = nil)
      @current_row = []
      @errors = []

      @context = DataShift::EmptyContext.new

      @load_object = LoadObject.new(object || new_load_object)
    end

    def new_load_object
      @load_object = klass.new
      @load_object
    end

    def create_context(method_binding, row_idx, data)
      @context = DataShift::Context.new(self, method_binding, row_idx, data)
      @context
    end

    # Only save object if all columns ok, or allow errors in individual columns
    def all_or_nothing?
      true
      # TODO: - read in from configration
    end

    def current_errors
      load_object.errors.full_messages
    end

    # We have our own error list available too
    def errors?
      !errors.empty? || !load_object.errors.empty?
    end

    def success
      reporter.add_loaded_object(load_object)
      logger.info("Successfully processed #{reporter.success_inbound_count}")
    end

    # Loading failed. Store a failed object and if requested roll back (destroy) the current load object
    # For use case where object saved early but subsequent required columns fail to process
    # so the load object is invalid

    def failure( error_messages, _delete_object = true)

      [*error_messages].each { |e| errors << e }

      if load_object
        reporter.add_failed_object(load_object)

        # TODO: - make this behaviour configurable with soem ind of rollback setting/funciton
        if load_object.respond_to?('destroy') && !load_object.new_record?
          klass = load_object.class
          load_object.destroy
          reset
        end
      end
    end

    # This method usually called during processing to avoid errors with associations like
    #   <ActiveRecord::RecordNotSaved: You cannot call create unless the parent is saved>
    # If the object is still invalid at this point probably indicates compulsory
    # columns on model have not been processed before associations on that model
    # TODO: smart ordering of columns dynamically ourselves rather than relying on incoming data order
    #
    def save_if_new
      return unless load_object.new_record?

      if load_object.valid?
        save
      else
        raise DataShift::SaveError.new("Cannot Save Invalid #{load_object.class} Record : #{current_errors}")
      end
    end

    def save_and_report

      if save
        logger.info("Successfully SAVED Object [#{load_object.id}] for [#{context.method_binding.pp}]")
        success
      else
        failure( current_errors )
        logger.error "Load failed while processing [#{context.method_binding.pp}]"
      end

    end

    def save
      return false unless  load_object

      logger.debug("SAVING #{load_object.class} : #{load_object.inspect}")
      begin
        load_object.save
      rescue => e
        logger.error( "Save Error : #{e.inspect} on #{load_object.class}")
        logger.error(e.backtrace)
        false
      end
    end

  end
end
