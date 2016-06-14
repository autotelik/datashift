# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   A header
#             Provides source <-> destination String mappings
#
module DataShift

  class Header

    attr_accessor :source, :destination

    def initialize(source:, destination: "")
      @source = source
      @destination = destination
    end

  end

end
