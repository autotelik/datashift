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
      
    require 'excel'

    class ExcelGenerator < GeneratorBase

      include DataShift::Logging
      
      attr_accessor :excel, :filename
  
      def initialize(filename)
        @filename = filename
      end

      # Create an Excel file template (header row) representing supplied Model
      # Options:
      # * <tt>:autosize</tt> - Autosize all the columns
      #
      def generate(klass, options = {})
     
        prepare(klass, options)
        
        @excel.set_headers(MethodDictionary.assignments[klass])

        logger.info("ExcelGenerator saving generated template #{@filename}")
        
        #@excel.autosize if(options[:autosize])
        
        @excel.write( @filename )
      end

      
      # Create an Excel file template (header row) representing supplied Model
      # and it's associations
      # 
      # Options:
      # * <tt>:autosize</tt> - Autosize all the columns
      #
      # * <tt>:exclude</tt> - Associations to exclude.
      #   You can specify a hash of {association_type => [array of association names] }
      #   to exclude from the template.
      #   
      # Possible association_type values are given by MethodDetail::supported_types_enum
      #  ... [:assignment, :belongs_to, :has_one, :has_many]
      #
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
        
       # @excel.autosize if(options[:autosize])
                
        @excel.write( filename() )
      end
      
      private
      
      def prepare(klass, options = {})
        @filename = options[:filename] if  options[:filename]
        
        logger.info("ExcelGenerator creating template with associations for class #{klass}")
        
        @excel = Excel.new()

        name  = options[:sheet_name] || klass.name
        
        sheet = @excel.create_worksheet( name ) 
    
        unless sheet
          logger.error("Excel failed to create WorkSheet for #{name}")
        
          raise "Failed to create Excel WorkSheet for #{name}" 
        end
        
        MethodDictionary.find_operators( klass )
      end
    end # ExcelGenerator
  
end # DataShift