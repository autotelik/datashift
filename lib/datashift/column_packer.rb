# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Dec 2012
# License::   MIT
#
# Details::   Helper for creating consistent import/export format
#             of model's attributes/associations
#
module DataShift

  module ColumnPacker

    include Delimiters

    # Return opposite of text delim - "hello, 'barry'" => '"hello, "barry""'
    def escape_text_delim
      return '"' if text_delim == "\'"
      "\'"
    end


    # Ensure a value is written to CSV correctly
    # TODO - better ways ?? - see transcoding and String#encode

    def escape_for_csv(value)
      text = value.to_s.gsub(text_delim, escape_text_delim()).gsub("\n", "\\n")

      text = "#{text_delim}#{text}#{text_delim}" if(text.include?(Delimiters::csv_delim))
      text
    end

    # Convert an AR instance to a single column
    #    e.g User  :  ":name = > 'tom', :role => 'developer'"
    #
    # OPTIONS
    #
    #     json:         Export association data in single column in JSON format

    def record_to_column(record, options = {})

      return "" if(record.nil? || (record.respond_to?(:each) && record.empty?) )

      return record.to_json if(options[:json]) # packs associations into single column

      data = []

      if( record.respond_to?(:each) )
        return "" if(record.empty?)

        record.each { |r| data << record_to_column(r, options) }

        "#{data.join(Delimiters::multi_assoc_delim)}"
      else
        record.serializable_hash.each do |name, value|
          text = value.to_s.gsub(text_delim, escape_text_delim())
          data << "#{name.to_sym} #{Delimiters::key_value_sep} #{text}"
        end

        "#{Delimiters::attribute_list_start}#{data.join(Delimiters::multi_value_delim)}#{Delimiters::attribute_list_end}"
      end

    end
    
    
    # Convert an AR instance to a set of CSV columns
    def record_to_csv(record, options = {})
      csv_data = record.serializable_hash.values.collect { |value| escape_for_csv(value) }

      [*options[:methods]].each { |x| csv_data << escape_for_csv(record.send(x)) if(record.respond_to?(x)) } if(options[:methods])
      
      csv_data.join( Delimiters::csv_delim )
    end

    
  end
end
