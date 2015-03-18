# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with Binder classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
module DataShift

  require 'datashift/binder'
  require 'datashift/querying'

  class LoaderBase

    include DataShift::Logging
    include DataShift::Querying
    include DataShift::Loading

    attr_reader :verbose

    def headers
      doc_context.headers
    end

    def reporter
      doc_context.reporter
    end

    # Options
    #
    #  :verbose          : Verbose logging and to STDOUT
    #
    def initialize(object_class, object = nil, options = {})

      @doc_context = DocContext.new(object_class)

      logger.info("Loading objects of type #{load_object_class} (#{object})")

      @verbose = (options[:verbose] == true)

      reset(object)
    end


    def report
      reporter.report
    end
=begin
    # Process columns with a default value specified
    def process_defaults()
      @populator.process_defaults
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
=end

    # Any Config under key 'LoaderBase' is merged over existing options - taking precedence.
    #  
    # Any Config under a key equal to the full name of the Loader class (e.g DataShift::SpreeEcom::ImageLoader)
    # is merged over existing options - taking precedence.
    # 
    #  Format :
    #  
    #    LoaderClass:
    #     option: value
    #
    def configure_from(yaml_file)

      logger.info("Reading Datashift loader config from: #{yaml_file.inspect}")

      data = YAML::load( ERB.new( IO.read(yaml_file) ).result )

      logger.info("Read Datashift config: #{data.inspect}")

      if(data['LoaderBase'])
        @config.merge!(data['LoaderBase'])
      end

      if(data[self.class.name])
        @config.merge!(data[self.class.name])
      end

      ContextFactory.configure(load_object_class, yaml_file)

      logger.info("Loader Options : #{@config.inspect}")
    end




    # Reset the loader, including database object to be populated, and load counts
    #
    def reset(object = nil)
      doc_context.reset
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
      current_value = @populator.current_value.to_s.split( Delimiters::multi_assoc_delim )
    end


  end

end