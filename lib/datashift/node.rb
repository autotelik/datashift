# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Jan 2016
# License::   MIT
#
# Details::  Store details of a Node, it's header and any Binding to a data operator

module DataShift
  class Node

    attr_accessor :index

    attr_accessor :header, :method_binding

    def initialize(source, method_binding: nil, index: -1)
      @index = index

      @header = DataShift::Header.new(source: source)

      @method_binding = method_binding

      unless method_binding
        model_method = DataShift::Operator.new(nil, :method)

        @method_binding = DataShift::MethodBinding.new(source, index, model_method)
      end
    end

    delegate :source, to: :header

    delegate :model_method, :operator, to: :method_binding



  end
end
