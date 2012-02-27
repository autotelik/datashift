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

  require 'generator_base'
      
  if(Guards::jruby?)

    require 'jruby/jexcel_file'

    class ExcelGenerator < GeneratorBase

      attr_accessor :filename
  
      def initialize(filename)
        @filename = filename
      end

      # Create an Excel file template (header row) representing supplied Model
    
      def generate(model, options = {})
        MethodDictionary.find_operators( model )

        @filename = options[:filename] if  options[:filename]

        excel = JExcelFile.new()

        if(options[:sheet_name] )
          excel.create_sheet( options[:sheet_name] ) 
        else
          excel.create_sheet( model.name )
        end
        
        raise "Failed to create Excel WorkSheet for #{model.name}" unless excel.sheet

        excel.set_headers(MethodDictionary.assignments[model])

        excel.save( @filename )
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
          
        work_list = (options[:with]) ? options[:with] : [:assignments, :belongs_to, :has_one, :has_many]
        
        headers = []
        
        work_list.each do |mdtype|
          method_details = MethodDictionary.send("#{mdtype}_for", klass)
        
          method_details.each {|md| headers << "#{md.operator}" }
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
    class  ExcelGenerator < GeneratorBase
      def initialize
        raise DataShift::BadRuby, "Please install and use JRuby for working with .xls files"
      end
    end
  end # jruby
  
end # DataShift