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
                  
        work_list.each do |op_type|
          list_for_class_and_op = details_mgr.get_list(op_type)
       
          next if(list_for_class_and_op.nil? || list_for_class_and_op.empty?)
         #if(work_list.include?(md.operator_type))
              #each do |mdtype|
          #end
          #if(MethodDictionary.respond_to?("#{mdtype}_for") )
           # method_details = MethodDictionary.send("#{mdtype}_for", klass)
        
            list_for_class_and_op.each {|md| headers << "#{md.operator}" }
          #else
           # puts "ERROR : Unknown option in :with [#{mdtype}]"
         
        end
        
        excel.set_headers( headers )
                
        data = []
        
        items.each do |record|
          
          MethodMapper.method_details[klass].each do |method_detail|   
            if(method_detail.operator_type == :assignment)
              data << record.send( method_detail.operator )
            end
          end
        end
        
        excel.set_row(2,1,items)

        excel.save( filename() )
      end
    end # ExcelGenerator

  else
    class  ExcelExporter < ExcelBase
      
      def initialize(filename)
        @filename = filename
        raise DataShift::BadRuby, "Apologies but Datashift Excel facilities currently need JRuby. Please switch to, or install JRuby"
      end
    end
  end # jruby
  
end # DataShift