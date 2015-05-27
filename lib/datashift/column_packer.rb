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


    def to_headers( records, associations = nil, options = {} )
      return if( !records.first.is_a?(ActiveRecord::Base) || records.empty?)

      only = *options[:only] ? [*options[:only]] : nil

      headers =[]

      if associations
        details_mgr = DataShift::MethodDictionary.method_details_mgrs[records.first.class]

        [*associations].each do |a|

          details_mgr.get_list(a).each do  |md|

            next if(only && !only.include?( md.name.to_sym ) )

            headers << "#{md.operator}"

          end
        end if(details_mgr)

      else

        headers = records.first.class.columns.collect( &:name )
      end

      headers
    end


    # Convert an AR instance to a single column
    #    e.g User  :  ":name = > 'tom', :role => 'developer'"
    #
    # OPTIONS
    #     with_only  Specify (as symbols) columns for association types to export
    #     json:         Export association data in single column in JSON format
    #
    def record_to_column(record, options = {})

      return "" if(record.nil? || (record.respond_to?(:each) && record.empty?) )

      with_only = *options[:with_only] ? [*options[:with_only]] : nil

      return record.to_json if(options[:json] && !with_only) # packs associations into single column

      if( record.respond_to?(:each) )

        return "" if(record.empty?)

        data = []

        record.each { |r| data << record_to_column(r, options); }

        if(options[:json])
          return data.to_json
        else
          return "#{data.join(Delimiters::multi_assoc_delim)}"
        end

      else

        data = options[:json] ? {} : []

        record.serializable_hash.each do |name, value|
          next if(with_only && !with_only.include?( name.to_sym ) )

          if(options[:json])
            data[name] = value
          else
            data << "#{name.to_sym} #{Delimiters::key_value_sep} #{value.to_s.gsub(text_delim, escape_text_delim)}"
          end
        end

        if(options[:json])#
          return data.to_json
        else
          "#{Delimiters::attribute_list_start}#{data.join(Delimiters::multi_value_delim)}#{Delimiters::attribute_list_end}"
        end

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
