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

    attr_accessor :current_row_index, :populator

    attr_reader :data, :method_binding

    def initialize( method_binding, row_idx, data)
      @method_binding = method_binding
      @current_row_index = row_idx
      @data = data

      @populator = ContextFactory::get_populator(method_binding)

    end

    def set_node( method_binding  )
      @method_binding = method_binding
    end

    def contains_data?
      !(value.nil? || value.to_s.empty?)
    end

  end
end