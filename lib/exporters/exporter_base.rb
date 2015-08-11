# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
#  Details::  Base class for Exporters, which provide services to export a Model
#             and it's data from database to an external format
#
require 'generators/file_generator'
module DataShift

  class ExporterBase < FileGenerator

    def initialize(filename)
      super filename
    end

  end

end
