# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# License::   MIT
#
# Details::   A collection of DataFlowNodes

require 'forwardable'

module DataShift

  # Acts as an array of Node

  class NodeCollection

    extend Forwardable

    attr_accessor :doc_context

    def_delegators :@nodes, *Array.delegated_methods_for_fwdable

    def initialize
      @nodes = []
    end

  end
end
