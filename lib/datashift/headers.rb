# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::   Holds the current headers amd any pre-processing
#             mapping done on them
#
require 'forwardable'

module DataShift

  class Headers

    extend Forwardable # For def_delegators

    attr_accessor :source

    attr_reader :previous_headers

    attr_reader :idx

    def_delegators :@headers, *Array.instance_methods.delete_if { |i| i.match(/__.*|class|object_id/) }

    def initialize(source, idx = 0, headers = [])
      @source = source
      @idx = idx
      @headers = headers
      @previous_headers = []
      @mapped = false
    end

    # Swap any raw inbound column headers for their mapped equivalent
    # mapping = {'Customer' => 'user'}
    #
    # In Excel/csv header is 'Customer',
    # this is now swapped for 'user' which is correct domain operator.
    #
    def swap_inbound( mapping )
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
