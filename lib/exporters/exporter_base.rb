# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#  Details::  Base class for Exporters, which provide services to export a Model
#             and it's data from database to an external format
#
module DataShift

  class ExporterBase < FileGenerator

    attr_accessor :configuration

    def initialize
      super

      @configuration = DataShift::Exporters::Configuration.configuration
    end

  end

end
