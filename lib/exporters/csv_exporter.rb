# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'exporter_base'
require 'csv'

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
      
    # Create an Excel file from list of ActiveRecord objects
    # Specify which associations to export via :with or :exclude
    # Possible values are : [:assignment, :belongs_to, :has_one, :has_many]
    #
    def export_with_associations(klass, items, options = {})
        
      MethodDictionary.find_operators( klass )
         
      MethodDictionary.build_method_details( klass )
           
      work_list = options[:with] || MethodDetail::supported_types_enum
        
      headers = []
      
      details_mgr = MethodDictionary.method_details_mgrs[klass]
                    
      data = []
      
      File.open(filename, "w") do |csv|
 
        # For each type belongs has_one, has_many etc find the operators
        # and create headers, then for each record call those operators
        work_list.each do |op_type|
          
          list_for_class_and_op = details_mgr.get_list(op_type)
       
          next if(list_for_class_and_op.nil? || list_for_class_and_op.empty?)

          # method_details = MethodDictionary.send("#{mdtype}_for", klass)
        
          list_for_class_and_op.each do |md| 
            headers << "#{md.operator}"
            items.each do |i| 
              data << i.send( md.operator )
            end
         
          end

          csv << headers.join(",")

          csv << "\n"
         
          data.each do |d|
            csv << d.join(",") << "\n"
      
          end
        end
      end
    end
    
    # Create CSV file representing supplied Model
    
    def generate(model, options = {})

      @filename = options[:filename] if  options[:filename]
    end

  end
end
