# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with MethodMapper classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
module DataShift

  require 'datashift/method_mapper'
  require 'datashift/querying'

  class LoaderBase

    include DataShift::Logging
    include DataShift::Querying
      
    attr_reader :headers

    attr_accessor :method_mapper

    attr_accessor :load_object_class, :load_object

    attr_accessor :reporter
    attr_accessor :populator
    
    attr_accessor :config, :verbose

    def options() return @config; end
    

    # Setup loading
    # 
    # Options to drive building the method dictionary for a class, enabling headers to be mapped to operators on that class.
    #  
    # find_operators [default = true] : Populate method dictionary with operators and method details
    #      
    # Options
    #  
    #  :reload           : Force load of the method dictionary for object_class even if already loaded
    #  :instance_methods : Include setter/delegate style instance methods for assignment, as well as AR columns
    #  :verbose          : Verboise logging and to STDOUT
    #
    def initialize(object_class, find_operators = true, object = nil, options = {})
      @load_object_class = object_class
      
      @populator = if(options[:populator].is_a?(String))
        ::Object.const_get(options[:populator]).new
      elsif(options[:populator].is_a?(Class))
        options[:populator].new
      else
        DataShift::Populator.new
      end
          
      # Gather names of all possible 'setter' methods on AR class (instance variables and associations)
      if((find_operators && !MethodDictionary::for?(object_class)) || options[:reload])
        #puts "DEBUG Building Method Dictionary for class #{object_class}"
        
        meth_dict_opts = options.extract!(:reload, :instance_methods)
        DataShift::MethodDictionary.find_operators( @load_object_class, meth_dict_opts)
        
        # Create dictionary of data on all possible 'setter' methods which can be used to
        # populate or integrate an object of type @load_object_class
        DataShift::MethodDictionary.build_method_details(@load_object_class)
      end
      
      @method_mapper = DataShift::MethodMapper.new
      @config = options.dup    # clone can cause issues like 'can't modify frozen hash'

      @verbose = @config[:verbose]
      
      @headers = []
     
      @reporter = DataShift::Reporter.new
      
      reset(object)
    end

    
    # Based on filename call appropriate loading function
    # Currently supports :
    #   Excel/Open Office files saved as .xls
    #   CSV files
    # 
    # OPTIONS :
    #  
    #  [:dummy]         : Perform a dummy run - attempt to load everything but then roll back
    #  
    #  strict           : Raise an exception of any headers can't be mapped to an attribute/association
    #  ignore           : List of column headers to ignore when building operator map
    #  mandatory        : List of columns that must be present in headers
    #  
    #  force_inclusion  : List of columns that do not map to any operator but should be includeed in processing.
    #                     This provides the opportunity for loaders to provide specific methods to handle these fields
    #                     when no direct operator is available on the model or it's associations
    #
    def perform_load( file_name, options = {} )

      raise DataShift::BadFile, "Cannot load #{file_name} file not found." unless(File.exists?(file_name))
        
      logger.info("Perform Load Options:\n#{options.inspect}")
      
      ext = File.extname(file_name)
      
      # TODO - make more modular - these methods doing too much, for example move the object creation/reset
      # out of these perform... methods to make it easier to over ride that behaviour
      if(ext.casecmp('.xls') == 0)
        perform_excel_load(file_name, options)
      elsif(ext.casecmp('.csv') == 0)
        perform_csv_load(file_name, options)
      else
        raise DataShift::UnsupportedFileType, "#{ext} files not supported - Try .csv or OpenOffice/Excel .xls"
      end
    end

    def report
      @reporter.report 
    end
    
    # Core API
    # 
    # Given a list of free text column names from a file, 
    # map all headers to a MethodDetail instance containing details on operator, look ups etc.
    # 
    # These are available through @method_mapper.method_details
    # 
    # Options:
    #    [:strict]          : Raise an exception of any headers can't be mapped to an attribute/association
    #    [:ignore]          : List of column headers to ignore when building operator map
    #    [:mandatory]       : List of columns that must be present in headers
    #  
    #    [:force_inclusion] : List of columns that do not map to any operator but should be includeed in processing.
    #                     
    #       This provides the opportunity for :
    #       
    #       1) loaders to provide specific methods to handle these fields, when no direct operator
    #        is available on the model or it's associations
    #
    #       2) Handle delegated methods i.e no direct association but method is on a model throuygh it's delegate
    #           
    #    [:include_all]     : Include all headers in processing - takes precedence of :force_inclusion
    #
    def populate_method_mapper_from_headers( headers, options = {} )
      @headers = headers
      
      mandatory = options[:mandatory] || []
               
      strict = (options[:strict] == true)
      
      begin 
        @method_mapper.map_inbound_headers_to_methods( load_object_class, @headers, options )
      rescue => e
        puts e.inspect, e.backtrace
        logger.error("Failed to map header row to set of database operators : #{e.inspect}")
        raise MappingDefinitionError, "Failed to map header row to set of database operators"
      end
      
      unless(@method_mapper.missing_methods.empty?)
        logger.warn("Following headings couldn't be mapped to #{load_object_class} \n#{@method_mapper.missing_methods.inspect}")
        raise MappingDefinitionError, "Missing mappings for columns : #{@method_mapper.missing_methods.join(",")}" if(strict)
      end

      unless(mandatory.empty? || @method_mapper.contains_mandatory?(mandatory) )
        @method_mapper.missing_mandatory(mandatory).each { |er| puts "ERROR: Mandatory column missing - expected column '#{er}'" }
        raise MissingMandatoryError, "Mandatory columns missing  - please fix and retry."
      end
      
      @method_mapper
    end


    #TODO - Move code into Populator
    # Process any defaults user has specified, for those columns that are not included in
    # the incoming import format
    def process_missing_columns_with_defaults()

      @populator.default_values.each do |dname, dv|

        method_detail = MethodDictionary.find_method_detail( load_object_class, dname )

        logger.debug "Processing default value #{dname} => #{dv}"
        @populator.prepare_and_assign(method_detail, @load_object, dv) if(method_detail)
      end
    end
    
    # Core API - Given a single free text column name from a file, search method mapper for
    # associated operator on base object class.
    # 
    # If suitable association found, process row data and then assign to current load_object
    def find_and_process(column_name, data)
      
      puts "WARNING: MethodDictionary empty for class #{load_object_class}" unless(MethodDictionary.for?(load_object_class))
        
      method_detail = MethodDictionary.find_method_detail( load_object_class, column_name )

      if(method_detail)
        process(method_detail, data)
      else
        puts "No matching method found for column #{column_name}"
        @load_object.errors.add(:base, "No matching method found for column #{column_name}")
      end
    end
    
    
    # Any Config under key 'LoaderBase' is merged over existing options - taking precedence.
    #  
    # Any Config under a key equal to the full name of the Loader class (e.g DataShift::SpreeHelper::ImageLoader)
    # is merged over existing options - taking precedence.
    # 
    #  Format :
    #  
    #    LoaderClass:
    #     option: value
    #
    def configure_from(yaml_file)

      data = YAML::load( File.open(yaml_file) )
      
      logger.info("Read Datashift loading config: #{data.inspect}")
        
      if(data['LoaderBase'])
        @config.merge!(data['LoaderBase'])
      end
       
      if(data[self.class.name])    
        @config.merge!(data[self.class.name])
      end
      
      @populator.configure_from(load_object_class, yaml_file)
      logger.info("Loader Options : #{@config.inspect}")
    end
    
    
    # Return the find_by operator and the rest of the (row,columns) data e.g
    #   price:0.99
    # 
    # Column headings will be used, if the row only contains data e.g
    #   0.99
    #   
    # We leave it to caller to manage any other aspects or problems in 'rest'
    #
    def get_operator_and_data(inbound_data)
        
      operator, data = inbound_data.split(Delimiters::name_value_delim)
     
      logger.debug("Parsed - operator : [#{operator}] - data : [#{data}]")
       
      # Find by operator embedded in row takes precedence over operator in column heading
      if((data.nil? || data.empty?) && @populator.current_method_detail.find_by_operator)
        # row contains data only so operator becomes header via method details
        data = operator
        operator = @populator.current_method_detail.find_by_operator
      end

      return operator, data
    end
    
    # Process a value string from a column.
    # Assigning value(s) to correct association on @load_object.
    # Method detail represents a column from a file and it's correlated AR associations.
    # Value string which may contain multiple values for a collection association.
    #
    def process(method_detail, value)  
      
      current_method_detail = method_detail

      current_value, current_attribute_hash = @populator.prepare_data(method_detail, value)
       
      # TODO - Move ALL of this into Populator properly
      if(current_method_detail.operator_for(:has_many))

        if(current_method_detail.operator_class && current_value)

          # there are times when we need to save early, for example before assigning to
          # has_and_belongs_to associations which require the load_object has an id for the join table
        
          save_if_new

          # A single column can contain multiple associations delimited by special char
          # Size:large|Colour:red,green,blue => ['Size:large', 'Colour:red,green,blue']
          columns = current_value.to_s.split( Delimiters::multi_assoc_delim )

          # Size:large|Colour:red,green,blue  =>
          #   find_by_size( 'large' )
          #   find_all_by_colour( ['red','green','blue'] )

          columns.each do |col_str|
            
            find_operator, col_values = get_operator_and_data( col_str )
                      
            raise "Cannot perform DB find by #{find_operator}. Expected format key:value" unless(find_operator && col_values)
             
            find_by_values = col_values.split(Delimiters::multi_value_delim)
            
            find_by_values << current_method_detail.find_by_value if(current_method_detail.find_by_value)           
              
            logger.info("Scanning for existing has_many associations [#{find_by_values}]")

            current_value = current_method_detail.operator_class.where(find_operator => find_by_values)

            logger.info("Scan result #{current_value.inspect}")
                
            unless(find_by_values.size == current_value.size)
              found = current_value.collect {|f| f.send(find_operator) }
              @load_object.errors.add( current_method_detail.operator, "Association with key(s) #{(find_by_values - found).inspect} NOT found")
              logger.error "Association #{current_method_detail.operator} with key(s) #{(find_by_values - found).inspect} NOT found - Not added."
              next if(current_value.empty?)
            end

            logger.info("Assigning #{current_value.inspect} (#{current_value.class}")
            
            # Lookup Assoc's Model done, now add the found value(s) to load model's collection
            @populator.prepare_and_assign(current_method_detail, @load_object, current_value)
          end # END HAS_MANY
        end
      else
        # Nice n simple straight assignment to a column variable
        #puts "INFO: LOADER BASE processing #{method_detail.name}"
        @populator.assign(@load_object)
      end
    end
    
    
    # Loading failed. Store a failed object and if requested roll back (destroy) the current load object
    # For use case where object saved early but subsequent required columns fail to process
    # so the load object is invalid
    
    def failure( object = @load_object, rollback = false)
      if(object)
        @reporter.add_failed_object(object)
      
        object.destroy if(rollback && object.respond_to?('destroy') && !object.new_record?)
        
        new_load_object # don't forget to reset the load object 
      end
    end

    def save
      return unless( @load_object )
      
      puts "DEBUG: SAVING #{@load_object.class} : #{@load_object.inspect}" if(verbose)
      begin
        return @load_object.save
      rescue => e
        failure
        puts "Error saving #{@load_object.class} : #{e.inspect}"
        logger.error e.backtrace
        raise "Error in save whilst processing column #{@current_method_detail.name}" if(@config[:strict])
      end
    end 
    
    # Reset the loader, including database object to be populated, and load counts
    #
    def reset(object = nil)
      @load_object = object || new_load_object
      @reporter.reset
    end

    
    def new_load_object
      @load_object = @load_object_class.new
      @load_object
    end

    def abort_on_failure?
      @config[:abort_on_failure].to_s == 'true'
    end

    def loaded_count
      reporter.loaded_objects.size
    end

    def failed_count
      reporter.failed_objects.size
    end


    # Check whether headers contains supplied list
    def headers_contain_mandatory?( mandatory_list )
      [ [*mandatory_list] - @headers].flatten.empty?
    end


    # Check whether headers contains supplied list
    def missing_mandatory_headers( mandatory_list )
      [ [*mandatory_list] - @headers].flatten
    end
    
    def find_or_new( klass, condition_hash = {} )
      @records[klass] = klass.find(:all, :conditions => condition_hash)
      if @records[klass].any?
        return @records[klass].first
      else
        return klass.new
      end
    end

    protected
    
    # Take current column data and split into each association
    # Supported Syntax :
    #  assoc_find_name:value | assoc2_find_name:value | etc
    def get_each_assoc
      @populator.current_value.to_s.split( Delimiters::multi_assoc_delim )
    end
      
    private

    # This method usually called during processing to avoid errors with associations like
    #   <ActiveRecord::RecordNotSaved: You cannot call create unless the parent is saved>
    # If the object is still invalid at this point probably indicates compulsory 
    # columns on model have not been processed before associations on that model
    # TODO smart ordering of columns dynamically ourselves rather than relying on incoming data order
    def save_if_new
      return unless(load_object.new_record?)
      
      if(load_object.valid?)  
        save
      else
        raise DataShift::SaveError.new("Cannot Save - Invalid #{load_object.class} Record - #{load_object.errors.full_messages}")
      end
    end
  
  end

end