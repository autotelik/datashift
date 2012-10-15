# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for generators, which provide serivrs to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    attr_accessor :filename, :headers, :remove_list
  
    def initialize(filename)
      @filename = filename
      @headers = []
      @remove_list =[]
    end
    
    
    def self.rails_columns
      @rails_standard_columns ||= [:id, :created_at, :created_on, :updated_at, :updated_on]
    end
  end

end