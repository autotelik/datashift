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
    # => :filename
    # => :call => List of methods to additionally call on each record
    #
    def export(records, options = {})
            
      first = records[0]
      
      return unless(first.is_a?(ActiveRecord::Base))
      
      f = options[:filename] || filename()
     
      File.open(f, "w") do |csv|
        
        headers = first.class.columns.collect { |col| col.name }
           
        [*options[:call]].each do |c| headers << c if(first.respond_to?(c)) end
             
        csv << headers.join(",") << "\n"
        
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv_data = []

          headers.each { |h|  csv_data << r.send(h) }
                          
          csv << csv_data.join(",") << "\n"
        end
      end
    end
      
    # Create an Excel file from list of ActiveRecord objects
    # Specify which associations to export via :with or :exclude
    # Possible values are : [:assignment, :belongs_to, :has_one, :has_many]
    #
    def export_with_associations(klass, records, options = {})
        
      f = options[:filename] || filename()
       
      MethodDictionary.find_operators( klass )
         
      MethodDictionary.build_method_details( klass )
           
      work_list = options[:with] || MethodDetail::supported_types_enum
    
      details_mgr = MethodDictionary.method_details_mgrs[klass]
                                 
      headers, csv_data = [], []
      
      File.open(f, "w") do |csv|

        work_list.each do |op_type|
          
          # For each type belongs has_one, has_many etc find the operators
          list_for_class_and_op = details_mgr.get_list(op_type)
       
          next if(list_for_class_and_op.nil? || list_for_class_and_op.empty?)

          # method_details = MethodDictionary.send("#{mdtype}_for", klass)
        
          list_for_class_and_op.each do |md| 
            headers << "#{md.operator}"
          end
        end
        
        csv << headers.join(",") << "\n"
        
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv_data = []

          headers.each { |h| csv_data << r.send(h) }
                          
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
