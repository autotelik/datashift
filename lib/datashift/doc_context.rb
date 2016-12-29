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

    # The current Node Context - method_binding (includes inbound_column), row, data
    attr_accessor :node_context

    # The inbound document headers
    attr_accessor :headers

    attr_accessor :progress_monitor, :reporters

    delegate :loaded_count, :failed_count, :processed_object_count, to: :progress_monitor

    def initialize( klass )
      reset_klass(klass)

      @headers = DataShift::Headers.new(:na)

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
      !load_object.errors.empty? || progress_monitor.current_status == :failure
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

    # Save the object and then report the outcome to ProgressMonitor, as either success or failure
    #
    def save_and_monitor_progress
      if(errors? && all_or_nothing?)
        # Error already logged with doc_context.failure
        logger.warn "SAVE skipped due to Errors for Row #{node_context.row_index} - #{node_context.method_binding.spp}"
      else
        if save
          @progress_monitor.success(load_object)

          logger.info("Successfully Processed [#{node_context.method_binding.spp}]")
          logger.info("Successfully SAVED Object #{@progress_monitor.success_inbound_count} - [#{load_object.id}]")
        else

          failed = FailureData.new(load_object, node_context, current_errors)

          @progress_monitor.failure(failed)

          logger.info("Failed to Process [#{node_context.method_binding.spp}]")
          logger.info("Failed to SAVE Object #{@progress_monitor.success_inbound_count} - [#{load_object.inspect}]")
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
