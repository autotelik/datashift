# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Aug 2016
# License::   MIT
#
# Details::   Holds the current context - the node we are dealing with
#             so requires the Inbound Column details, the associated ModelMethod
#             and the row node containing the actual data to apply via the model method operator
#

module DataShift

  class NodeContext

    include DataShift::Logging

    attr_accessor :doc_context, :method_binding, :row_index

    attr_accessor :populator

    attr_reader :data

    def initialize(doc_context, method_binding, row_idx, data)
      @doc_context = doc_context
      @method_binding = method_binding
      @row_index = row_idx
      @data = data

      @populator = PopulatorFactory.get_populator(method_binding)
    end

    delegate :model_method, :operator, to: :method_binding

    def contains_data?
      !(data.nil? || data.to_s.empty?)
    end

    def next_update?
      false # for now create only
      # TODO : Support UPDATES
      # next = ProcessingRules.next_action(method_binding )
      # next == :update
    end

    def process
      populator.prepare_and_assign(self, doc_context.load_object, data)
    rescue => x

      failed = FailureData.new( doc_context.load_object, self, x.message)

      failed.error_messages <<  "Failed to process node : #{method_binding.pp}"

      doc_context.progress_monitor.failure(failed)

      logger.error("#{x.backtrace.first} : #{x.message}")
      raise x
    end

  end

  class EmptyContext < NodeContext

    def initialize
      super(NilClass, DataShift::NoMethodBinding.new, -1, [])
    end
  end

end
