# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
# Details::   A collection of DataFlowNodes

require 'forwardable'

module DataShift

  class NodeCollection

    extend Forwardable

    def_delegators :@nodes, *Array.instance_methods.delete_if { |i| i.match(/__.*|class|object_id/) }

    def initialize()
      @nodes = []
      @configuration = DataShift::Configuration.call
    end

  end
end
