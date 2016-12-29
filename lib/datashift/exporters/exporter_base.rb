# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#  Details::  Base class for Exporters, which provide services to export a Model
#             and it's data from database to an external format
#
module DataShift

  class ExporterBase

    attr_accessor :configuration
    attr_accessor :file_name

    def initialize
      @configuration = DataShift::Exporters::Configuration.call
    end

  end

end
