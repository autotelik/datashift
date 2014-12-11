# Copyright:: Autotelik Media Ltd
# Author ::   Tom Statter
# Date ::     July 2010
# License::   
#
# Details::   Simple internal representation of Csv File

require 'csv'

class CSV

  # TOFIX .. now we use CSV class this probably not needed
  include DataShift::ColumnPacker

  # Helpers for dealing with Active Record models and collections
    # Specify array of operators/associations to include - possible values are :
    #     [:assignment, :belongs_to, :has_one, :has_many]

    def ar_to_headers( records, associations = nil )
      return if( !records.first.is_a?(ActiveRecord::Base) || records.empty?)

      headers =[]

      if associations
        details_mgr = DataShift::MethodDictionary.method_details_mgrs[records.first.class]

        associations.each do |a|
          details_mgr.get_list(a).each { |md| headers << "#{md.operator}" }
        end if(details_mgr)

      else
        headers = records.first.class.columns.collect( &:name )
      end

      add_row(headers)
    end

    # Convert an AR instance to a set of CSV columns
    # Additional non instance data can be included by supplying list of methods to call
    # on the record
    def ar_to_csv(record, options = {})
      csv_data = record.serializable_hash.values.collect { |c| escape_for_csv(c) }

      [*options[:methods]].each { |x| csv_data << escape_for_csv(record.send(x)) if(record.respond_to?(x)) } if(options[:methods])

      add_row(csv_data)
    end

end
