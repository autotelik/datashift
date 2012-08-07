# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'exporter_base'

module DataShift

  class CsvExporter < ExporterBase

    def initialize(filename)
      super(filename)
    end

    # Create CSV file from set of ActiveRecord objects
    # Options :
    # => :call => List of methods to additionally export on each record
    #
    def export(records, options = {})
      
      require 'csv'
      File.open(filename, "w") do |csv|
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv_data = []

          if(options[:call].is_a?(Array))
            options[:call].each { |c| csv_data << r.send(c) }
          end
          
          r.class.columns.each { |col| csv_data << r.send(col.name) }
                    
          csv << csv_data.join(",") << "\n"
        end
      end
    end
      
    # Create CSV file representing supplied Model
    
    def generate(model, options = {})

      @filename = options[:filename] if  options[:filename]
    end

  end
end
