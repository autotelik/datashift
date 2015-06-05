# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Holds the current context - the node we are dealing with
#             so requires the Inbound Column details, the associated ModelMethod
#             and the row node containing the actual data to apply via the model method operator
#

module DataShift

  class Context

    attr_accessor :current_row_index, :populator, :doc_context

    attr_reader :data, :method_binding

    def initialize(doc_context, method_binding, row_idx, data)
      @doc_context = doc_context
      @method_binding = method_binding
      @current_row_index = row_idx
      @data = data

      @populator = ContextFactory::get_populator(method_binding)
    end

    def set_node( method_binding  )
      @method_binding = method_binding
    end

    def contains_data?
      !(data.nil? || data.to_s.empty?)
    end

    def next_update?
      false   # for now create only
      #TODO :
      # next = ProcessingRules.next_action(method_binding )
      # next == :update
    end


    def process

       begin
         populator.prepare_and_assign(self, doc_context.load_object, data)
       rescue => x

         doc_context.errors << "Failed to process node : #{method_binding.pp}"

         logger.error(doc_context.errors.last)
         logger.error("#{x.backtrace.first} : #{x.message}")

         puts x.backtrace.first, x.message
         raise x
       end
    end

  end

  class EmptyContext < Context

    def initialize
     super(NilClass, DataShift::NoMethodBinding.new , -1, [])
    end
  end

end