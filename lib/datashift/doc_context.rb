# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Holds the current context in relation to the Document we are dealing with
#

module DataShift

  class DocContext

    attr_reader :klass

    attr_accessor :current_object

    # The inbound document headers
    attr_accessor :headers

    attr_accessor :reporter

    # Options :
    #    formatter
    #    populator
    #
    def initialize( klass  )
      @klass = klass

      @headers = DataShift::Headers.new(:na)
    end

    # Reset the database object to be populated
    #
    def reset(object = nil)
      @current_object = object || new_load_object
    end


    def new_load_object()
      @current_object = klass.new()
      @current_object
    end

  end
end