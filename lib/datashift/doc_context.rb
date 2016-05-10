# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   The document we are dealing with
#             Holds the headers, load object and access to reports for this Document
#             Holds the current node_context (e.g column being processed) in relation to the Document
#
module DataShift

  class DocContext

    include DataShift::Logging

    attr_reader :klass

    attr_accessor :load_object

    # The current Node
    attr_accessor :node_context

    # The inbound document headers
    attr_accessor :headers

    attr_accessor :progress_monitor, :reporters

    def initialize( klass )
      reset_klass(klass)

      @headers  = DataShift::Headers.new(:na)

      @progress_monitor = ProgressMonitor.new

      @reporters = [DataShift::Reporters::BasicStdoutReporter.new(@progress_monitor)]
    end

    def reset_klass( klass )
      @klass = klass
      reset
    end

    # Reset the database object to be populated
    #
    def reset(object = nil)
      @node_context = DataShift::EmptyContext.new

      @load_object = LoadObject.new(object || new_load_object)
    end

    def new_load_object
      @load_object = klass.new
      @load_object
    end

    def create_node_context(method_binding, row_idx, data)
      @node_context = DataShift::NodeContext.new(self, method_binding, row_idx, data)
      @node_context
    end

    # Only save object if all columns ok, or allow errors in individual columns
    def all_or_nothing?
      true
      # TODO: - read in from configration
    end

    def current_errors
      load_object.errors.full_messages
    end

    def errors?
      !load_object.errors.empty?
    end

    def success
      @progress_monitor.add_loaded_object(load_object)
      logger.info("Successfully processed #{@progress_monitor.success_inbound_count}")
    end

    # Loading failed. Store a failed object and if requested roll back (destroy) the current load object
    # For use case where object saved early but subsequent required columns fail to process
    # so the load object is invalid

    def failure( error_messages, _delete_object = true)

      logger.error "Failure(S) reported : #{[*error_messages].inspect}"

      failed = FailureData.new(load_object, node_context, error_messages)

      @progress_monitor.add_failed_object(failed)

      # TODO: - make this behaviour configurable with some kind of rollback setting/functoon
      if load_object.respond_to?('destroy') && !load_object.new_record?
        load_object.destroy
        reset
      end if load_object

    end

    # This method usually called during processing to avoid errors with associations like
    #   <ActiveRecord::RecordNotSaved: You cannot call create unless the parent is saved>
    # If the object is still invalid at this point probably indicates compulsory
    # columns on model have not been processed before associations on that model.
    #
    # You can provide a custom sort function to the Collection of model methods (which are comparable) to fix this.
    #
    def save_if_new
      return unless load_object.new_record?

      return save if load_object.valid?

      raise DataShift::SaveError, "Cannot Save Invalid #{load_object.class} Record : #{current_errors}"
    end

    def save_and_report
      if(errors? && all_or_nothing?)
        # Error already logged with doc_context.failure
        logger.warn "Row #{current_row_idx} contained errors - SAVE has been skipped"
      else
        if save
          logger.info("Successfully SAVED Object [#{load_object.id}] for [#{context.method_binding.pp}]")
          success
        else
          logger.error( "Save FAILED - logging failed object [#{load_object.id}] ")
          failure( current_errors )
        end
      end
    end

    def save
      return false unless  load_object

      logger.debug("SAVING #{load_object.class} : #{load_object.inspect}")
      begin
        load_object.save!
      rescue => e
        logger.error( "Save Error : #{e.inspect} on #{load_object.class}")
        logger.error(e.backtrace)
        false
      end
    end

  end
end
