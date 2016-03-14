# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  File based generators
#
require 'generator_base'

module DataShift

  class FileGenerator < DataShift::GeneratorBase

    attr_accessor :file_name

    def initialize
      super
    end

  end

end
