# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     March 2015
# License::   MIT
#
# Details::   Manage the current loader object
#
require 'to_b'
require 'logging'

module DataShift

  class LoadObject
    
    include DataShift::Logging

    attr_accessor :load_object

    def initialize( current_object = nil)
      @load_object = current_object
    end
    
  end
  
end
