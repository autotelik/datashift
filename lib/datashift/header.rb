# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   A column header.
#
#             Calling to_s on a header object will return the presentation value
#
module DataShift

  class Header

    attr_accessor :source, :presentation

    def initialize(source:, presentation: nil)
      @source = source
      @presentation = presentation || source
    end

    def ==(rhs)
      puts "== Called with #{rhs}"
      @source == rhs
    end

    def to_s
      presentation
    end

  end

end
