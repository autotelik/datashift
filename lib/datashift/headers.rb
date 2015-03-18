# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Jan 2015
# License::   MIT
#
# Details::   Holds the current headers amd any pre-processing
#             mapping done on them
#

module DataShift

  class Headers

    extend Forwardable # For def_delegators

    attr_accessor :source

    attr_reader :previous_headers

    attr_reader :idx

    def_delegators :@headers, *Array.instance_methods.delete_if {|i| i.match(/__.*|class|object_id/)}

    def initialize(source, idx = 0, headers = [])
      @source = source
      @idx = idx
      @headers = headers
      @previous_headers = []
      @mapped = false
    end


    def map( mapping )
      @previous_headers = @headers.dup
      mapping.each do |m, v|
        @headers.index_at(m)
        @headers[i] = v
      end
      @mapped = true
    end

    def mapped?
      @mapped
    end

    def row_index
      idx
    end

  end
end