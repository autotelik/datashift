# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Jan 2016
# License::   MIT
#
# Details::  Store details of a Column, either inbound or outbound

module DataShift
  class Node

    attr_accessor :tag, :index, :header, :operator

    def initialize(tag, operator: nil, index: -1)
      @tag = tag.to_s
      @index = index
      @header = DataShift::Header.new(source: tag)

      @operator = operator
    end

    delegate :source, to: :header
    delegate :destination, to: :header

  end
end
