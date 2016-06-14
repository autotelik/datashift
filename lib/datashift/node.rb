# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Jan 2016
# License::   MIT
#
# Details::  Store details of a Column, either inbound or outbound

module DataShift
  class Node

    attr_accessor :name, :index, :header, :operator

    def initialize( in_name, index = -1)
      @name = in_name.to_s
      @index = index
      @header = nil
    end

  end
end
