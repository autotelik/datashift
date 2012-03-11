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

      include DataShift::Logging
      
      attr_accessor :excel, :filename
  
      def initialize(filename)
        @filename = filename
      end

      # Create an Excel file template (header row) representing supplied Model
    
      def generate(klass, options = {})
     
        prepare(klass, options)
        
        @excel.set_headers(MethodDictionary.assignments[klass])

        logger.info("ExcelGenerator saving generated template #{@filename}")
        
        @excel.save( @filename )
      end

      
      # Create an Excel file from list of ActiveRecord objects
      # To remove type(s) of associations specify option :
      #   :exclude => [type(s)]
      #   
      # Possible values are given by MethodDetail::supported_types_enum
      #  ... [:assignment, :belongs_to, :has_one, :has_many]
      #
      # Options
      def generate_with_associations(klass, options = {})

        prepare(klass, options)
         
        MethodDictionary.build_method_details( klass )
           
        work_list = MethodDetail::supported_types_enum.to_a
        work_list -= options[:exclude].to_a
         
        headers = []
      
        details_mgr = MethodDictionary.method_details_mgrs[klass]
                  
        work_list.each do |op_type|
          list_for_class_and_op = details_mgr.get_list(op_type)
          
          next if(list_for_class_and_op.nil? || list_for_class_and_op.empty?)
          list_for_class_and_op.each {|md| headers << "#{md.operator}" }
        end
        
        @excel.set_headers( headers )
                
        @excel.save( filename() )
      end
      
      private
      
      def prepare(klass, options = {})
        @filename = options[:filename] if  options[:filename]
        
        logger.info("ExcelGenerator creating template with associations for class #{klass}")
        
        @excel = JExcelFile.new()

        if(options[:sheet_name] )
          @excel.create_sheet( options[:sheet_name] ) 
        else
          @excel.create_sheet( klass.name )
        end
        
        unless @excel.sheet
          logger.error("Excel failed to create WorkSheet for #{klass.name}")
        
          raise "Failed to create Excel WorkSheet for #{klass.name}" 
        end
        
        MethodDictionary.find_operators( klass )
      end
    end # ExcelGenerator

  else
    class  ExcelGenerator < GeneratorBase
      
      def initialize(filename)
        @filename = filename
        raise DataShift::BadRuby, "Apologies but DataShift Excel facilities currently need JRuby. Please switch to, or install JRuby"
      end
    end
  end # jruby
  
end # DataShift