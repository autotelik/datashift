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
require 'generator_base'
require 'excel'
  
module DataShift
      
  class ExcelGenerator < GeneratorBase

    include DataShift::Logging
      
    attr_accessor :excel
  
    def initialize(filename)
      super(filename)
    end

    # Create an Excel file template (header row) representing supplied Model
    # Options:
    # * <tt>:filename</tt>
    # * <tt>:autosize</tt> - Autosize all the columns
    #
    def generate(klass, options = {})
     
      prepare_excel(klass, options)

      prep_remove_list(options)  
            
      @headers = MethodDictionary.assignments[klass]
      
      @headers.delete_if{|h| @remove_list.include?( h.to_sym ) }
      
      @excel.set_headers( @headers )

      logger.info("ExcelGenerator saving generated template #{@filename}")
        
      #@excel.autosize if(options[:autosize])
        
      @excel.write( @filename )
    end

      
    # Create an Excel file template (header row) representing supplied Model
    # and it's associations
    # 
    # Options:
    # * <tt>:filename</tt>
    # * <tt>:autosize</tt> - Autosize all the columns
    #
    # * <tt>:exclude</tt> - Association TYPE(s) to exclude.
    #   You can specify a hash of {association_type => [array of association names] }
    #   to exclude from the template.
    #   
    #     Possible association_type values are given by MethodDetail::supported_types_enum
    #       ... [:assignment, :belongs_to, :has_one, :has_many]
    #       
    # * <tt>:remove</tt> - Association NAME(s) to remove .. :title, :id, :name
    # .
    # * <tt>:remove_rails</tt> - Remove Rails DB columns :
    #           :id, :created_at, :created_on, :updated_at, :updated_on
    #   
    def generate_with_associations(klass, options = {})

      prepare_excel(klass, options)
         
      MethodDictionary.build_method_details( klass )
           
      work_list = MethodDetail::supported_types_enum.to_a - [ *options[:exclude] ]
        
      prep_remove_list(options)    
      
      @headers = []
      
      details_mgr = MethodDictionary.method_details_mgrs[klass]
                  
      work_list.each do |assoc_type|
        method_details_for_assoc_type = details_mgr.get_list_of_method_details(assoc_type)
          
        next if(method_details_for_assoc_type.nil? || method_details_for_assoc_type.empty?)
        
        method_details_for_assoc_type.each do |md| 
          comparable_association = md.operator.to_s.downcase.to_sym

          i = remove_list.index { |r| r == comparable_association }
             
          (i) ? remove_list.delete_at(i) : headers << "#{md.operator}"
        end
      end
        
      @excel.set_headers( headers )
        
      # @excel.autosize if(options[:autosize])
                
      @excel.write( filename() )
    end
      
    private
      
    # Take options and create a list of symbols to remove from headers
    # 
    def prep_remove_list( options )
      @remove_list = [ *options[:remove] ].compact.collect{|x| x.to_s.downcase.to_sym }
         
      @remove_list += GeneratorBase::rails_columns if(options[:remove_rails])
    end
    
    
    def prepare_excel(klass, options = {})
      @filename = options[:filename] if  options[:filename]
        
      logger.info("ExcelGenerator creating template with associations for class #{klass}")
        
      @excel = Excel.new()

      name  = options[:sheet_name] || klass.name
        
      sheet = @excel.create_worksheet( :name => name ) 
    
      unless sheet
        logger.error("Excel failed to create WorkSheet for #{name}")
        
        raise "Failed to create Excel WorkSheet for #{name}" 
      end
        
      MethodDictionary.find_operators( klass )
    end
  end # ExcelGenerator
  
end # DataShift