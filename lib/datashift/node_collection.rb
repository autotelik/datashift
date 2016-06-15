# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
# Details::   A collection of DataFlowNodes

require 'forwardable'

module DataShift

  # Acts as an array

  class NodeCollection

    extend Forwardable

    def_delegators :@nodes, *Array.delegated_methods_for_fwdable

    def initialize()
      @nodes = []
      @configuration = DataShift::Configuration.call
    end

  end
end
