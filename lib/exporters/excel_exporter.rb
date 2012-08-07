# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to Excel '97(-2007) file format.
#
# TOD : Can we switch between .xls and XSSF (POI implementation of Excel 2007 OOXML (.xlsx) file format.)
#
#
module DataShift

  require 'exporter_base'
      
  if(Guards::jruby?)

    require 'jruby/jexcel_file'

    class ExcelExporter < ExporterBase

      attr_accessor :filename
  
      def initialize(filename)
        @filename = filename
      end

  
      # Create an Excel file from list of ActiveRecord objects
      def export(records, options = {})

        excel = JExcelFile.new()

        if(options[:sheet_name] )
          excel.create_sheet( options[:sheet_name] ) 
        else
          excel.create_sheet( records.first.class.name )
        end
      
        excel.ar_to_headers(records)
        
        excel.ar_to_xls(records)

        excel.save( filename() )
      end
      
      # Create an Excel file from list of ActiveRecord objects
      # Specify which associations to export via :with or :exclude
      # Possible values are : [:assignment, :belongs_to, :has_one, :has_many]
      #
      def export_with_associations(klass, items, options = {})

        excel = JExcelFile.new()

        if(options[:sheet_name] )
          excel.create_sheet( options[:sheet_name] ) 
        else
          excel.create_sheet( items.first.class.name )
        end
        
        MethodDictionary.find_operators( klass )
         
        MethodDictionary.build_method_details( klass )
           
        work_list = options[:with] || MethodDetail::supported_types_enum
        
        headers = []
        puts "work_list :  [#{work_list.inspect}]"
      
        details_mgr = MethodDictionary.method_details_mgrs[klass]

                        
        data = []
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
        
          excel.set_headers( headers )
        
          row_index = 1
        
          items.each do |datum| 
            excel.create_row(row_index += 1)
            excel.ar_to_xls_row(1, datum)
          end
           
          excel.save( filename() )
        end
      end
    end # ExcelGenerator

  else
    class  ExcelExporter < ExporterBase
      
      def initialize(filename)
        raise DataShift::BadRuby, "Apologies but DataShift Excel facilities currently need JRuby. Please switch to, or install JRuby"
      end
    end
  end # jruby
  
end # DataShift