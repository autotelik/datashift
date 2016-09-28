# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   A column header
#
module DataShift

  class Header

    attr_accessor :source, :presentation

    def initialize(source:)
      @source = source
      @presentation = source
    end

    def to_s
      presentation
    end

  end

end
