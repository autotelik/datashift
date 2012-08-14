# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for Exporters, which provide services to export a Model
#             and it's data from database to an external format
#
module DataShift

  class ExporterBase

    attr_accessor :filename
  
    def initialize(filename)
      @filename = filename
    end
    
  end

end