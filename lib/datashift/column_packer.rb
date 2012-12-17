# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Dec 2012
# License::   MIT
#
# Details::   Helper for creating consistent import/export format
#             of model's attributes/associations
# 
#
require 'exporter_base'
require 'csv'

module DataShift

  module ColumnPacker

    
    def text_delim
      @text_delim ||= "\'"
    end

    def text_delim=(x)
      @text_delim = x
    end
    
    # Return opposite of text delim - "hello, 'barry'" => '"hello, "barry""'
    def escape_text_delim
      return '"' if text_delim == "\'"
      "\'"
    end
    
 
    # Convert an AR instance to a single column
  
    def record_to_column(record, attribute_delim = Delimiters::csv_delim) 
    
      csv_data = []
      record.serializable_hash.each do |name, value|
        value = 'nil' if value.nil?
        text = value.to_s.gsub(@text_delim, escape_text_delim())
        csv_data << "#{name.to_sym} => #{text}"
      end
      "#{csv_data.join(attribute_delim)}"
    end
    
    
    # Convert an AR instance to a set of CSV columns
    def record_to_csv(record, options = {})
      csv_data = record.serializable_hash.values.collect { |value| escape_for_csv(value) }

      [*options[:methods]].each { |x| csv_data << escape_for_csv(record.send(x)) if(record.respond_to?(x)) } if(options[:methods])
      
      csv_data.join( Delimiters::csv_delim )
    end
    
    def escape_for_csv(value)
      text = value.to_s.gsub(@text_delim, escape_text_delim())
      
      text = "#{@text_delim}#{text}#{@text_delim}" if(text.include?(Delimiters::csv_delim)) 
      text
    end
    
  end
end
