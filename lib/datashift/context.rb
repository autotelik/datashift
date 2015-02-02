# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Holds the current context - the node we are dealing with
#             so requires the Inbound Column details, the associated MethodDetails
#             and the row node containing the actual data to apply via the method detail
#

module DataShift
  class Context

    # Options :
    #    formatter
    #    populator
    #
    def initialize( method_binding  )

      @populator = ContextFactory::get_populator(method_binding)

    end
  end
end