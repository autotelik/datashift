# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   A header
#             The source text
#
module DataShift

  class Header

    attr_accessor :source

    def initialize(source:)
      @source = source
    end

  end

end
