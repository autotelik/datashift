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
    # => :text_delim => Char to use to delim columns, useful when data contain embedded ','
    # => :call => List of methods to additionally call on each record
    #
    def export(records, options = {})
      
         
      first = records[0]
      
      return unless(first.is_a?(ActiveRecord::Base))
      
      f = options[:filename] || filename()
      
      char = options[:text_delim] || "'"  
      
      File.open(f, "w") do |csv|
        
        headers = first.class.columns.collect { |col| col.name }
           
        [*options[:call]].each do |c| headers << c if(first.respond_to?(c)) end
             
        csv << headers.join(",") << "\n"
        
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv_data = []

          headers.each { |h| 
            col = r.send(h).to_s
            col.include?(',') ? csv_data << "#{char}#{col}#{char}" : csv_data <<  col
          }
                          
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
        
      # builds all possible operators
      MethodDictionary.build_method_details( klass )
           
      work_list = options[:with] ? Set(options[:with]) : MethodDetail::supported_types_enum
      
      assoc_work_list = work_list.dup

      details_mgr = MethodDictionary.method_details_mgrs[klass]
            
      File.open(f, "w") do |csv|  
      
        headers, assignments, csv_data = [], []
        # headers
        if(work_list.include?(:assignment))
          assignments << details_mgr.get_list(:assignment).collect( &:operator)
          assoc_work_list.delete :assignment
        end
         
        headers << assignments.flatten!
        # based on users requested list ... belongs_to has_one, has_many etc ... select only those operators
        assoc_work_list.collect do |op_type|     
          headers << details_mgr.get_list(op_type).collect( &:operator).flatten
        end
        puts headers
          
        csv << headers.join(",") << "\n"
        
        records.each do |r|
          next unless(r.is_a?(ActiveRecord::Base))
          
          csv_data = []

          csv_data = assignments.collect {|c| r.send(c) }

          assoc_work_list.each do |op_type| 
            details_mgr.get_operators(op_type).each do |operator| 
              assoc_object = r.send(operator) 
              if(assoc_object.is_a?ActiveRecord::Base)
                csv_data << assoc_object.attributes
              elsif(assoc_object.is_a? Array)
                csv_data << assoc_object.collect( &:attributes )
              else
                csv_data << ""
              end
            end
          end               
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
