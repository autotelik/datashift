# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Read mappings and provide cache type services for source=>destination mappings
#
require 'erubis'

module DataShift

  class Configuration

    # List of association +TYPES+ to INCLUDE [:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
    # Defaults to [:assignment, :enum]
    #
    # @param [Array<#call>] List of association Types to include (:has_one etc)
    # @return [Array<#call>]
    #
    attr_accessor :with

    # When calling the export with associations methods the default
    # is to include ALL all association TYPES as defined by
    #   ModelMethod.supported_types_enum
    #
    # This can be used to reduce this down to only export specific types
    #
    # @param [Array<#call>] List of association Types to EXCLUDE (:has_one etc)
    # @return [Array<#call>]
    #
    attr_accessor :exclude

    # @param [Array<#call>] List of columns to remove from  files
    # @return [Array<#call>]
    #
    attr_accessor :remove_columns

    # List of headers/columns that are Mandatory i.e must be present in the inbound data
    #
    # @param [Array<#call>] List of headers/columns that are Mandatory
    # @return [Array<#call>]
    #
    attr_accessor :mandatory

    # @param [Boolean] Remove standard Rails cols like :id, created_at etc
    # Default is false - i.e id, created_at etc are included by default
    # @return [Boolean]
    #
    attr_accessor :remove_rails

    # When performing import, default is to ignore any columns that cannot be mapped  (via headers)
    # To raise an error set strict => true
    # Defaults to `false`. Set to `true` to cause exceptions to be thrown
    # The setting is ignored if routes are disabled.
    # @param [Boolean] value
    # @return [Boolean]
    attr_accessor :strict

    # When performing writes use update methods that write immediately to DB
    # and use validations.
    #
    # Validations can ensure business logic but this can be far less efficient as writes to DB once per column
    #
    # To raise an error set strict => true
    # Default  is to use more efficient but less strict attribute writing,
    # no write to DB/No validations run
    # @param [Boolean] value
    # @return [Boolean]
    attr_accessor :update_and_validate

    # Controls the amount of information written to the log
    # Defaults to `false`. Set to `true` to cause extensive progress messages to be logged
    # @param [Boolean] value
    # @return [Boolean]
    attr_accessor :verbose

    # Do everything except commit changes.
    # For import save will not be called on the final object
    # Defaults to `false`. Set to `true` to cause extensive progress messages to be logged
    # @param [Boolean] value
    # @return [Boolean]
    attr_accessor :dummy_run

    # Expand association data into multiple columns
    #
    # @param [Boolean]
    # @return [Boolean]
    #
    attr_accessor :expand_associations

    # When importing/exporting associations default is to include ALL associations of included TYPES
    #
    # Specify associations by name to remove
    #
    # @param [Array<#call>] List of association Names to EXCLUDE
    # @return [Array<#call>]
    #
    attr_accessor :exclude_associations

    #  List of external columns that do not map to any operator but should be included in processing.
    #
    #  Example use cases
    #
    #  Provides the opportunity for loaders to provide specific methods to handle columns
    #  that do not map directly to a model's operators or associations
    #
    #  Enable handling delegated methods i.e no direct association but method is on a model through it's delegate
    #
    # @param [Array] value
    # @return [Array]
    attr_accessor :force_inclusion_of_columns

    #  All external columns should be included in processing whether or not they automatically map to an operator
    #
    # @param [Boolean]
    # @return [Boolean]
    #
    attr_accessor :include_all_columns

    def self.rails_columns
      @rails_standard_columns ||= [:id, :created_at, :created_on, :updated_at, :updated_on]
    end

    def initialize
      @with = [:assignment, :enum]
      @exclude = []
      @remove_columns = []

      @strict = false
      @verbose = false
      @dummy_run = false
      @force_inclusion_of_columns = []
      @exclude_associations = []

      @expand_associations = false

      # default to more efficient attribute writing - no write to DB/no validations run
      @update_and_validate = false
    end

    # @return [DataShift::Configuration] DataShift's current configuration
    def self.call
      @configuration ||= Configuration.new
    end

    def self.reset
      @configuration = Configuration.new
    end

    # Set DataShift's configuration
    # @param config [DataShift::Configuration]
    class << self
      attr_writer :configuration
    end

    # Modify DataShift's current configuration
    # @yieldparam [DataShift::Configuration] config current DataShift config
    # ```
    # DataShift::Configuration.call do |config|
    #   config.verbose = false
    # end
    # ```
    def self.configure
      yield call
    end

    # Prepare the operators types in scope based on number of configuration attributes
    # Default is assignment only
    #
    # Responds to Configuration params :
    #
    #   with: [:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
    #
    #   with: :all -> all op types
    #
    #   exclude: - Remove any of [::assignment, :enum, :belongs_to, :has_one, :has_many, :method]
    #
    def op_types_in_scope

      types_in_scope = if with_all?
                         ModelMethod.supported_types_enum.dup
                       else
                         [*@with].dup
                       end

      types_in_scope -= [*@exclude]

      types_in_scope
    end

    def op_type_in_scope?( model_method )
      op_types_in_scope.include? model_method.operator_type
    end

    def with_all?
      [*@with].include?(:all)
    end

    # Take options and create a list of symbols to remove from headers
    #
    # Rails columns like id, created_at etc are included by default
    # Specify option :remove_rails to remove them from output
    #
    def prep_remove_list
      remove_list = [*remove_columns].compact.collect { |x| x.to_s.downcase.to_sym }

      remove_list += DataShift::Configuration.rails_columns if remove_rails

      remove_list
    end

    # Modify DataShift's current Export configuration from an options hash
    def self.from_hash( options )
      DataShift::Configuration.configure do |config|
        options.each do |key, value|
          config.send("#{key}=", value) if(config.respond_to?(key))
        end
      end
    end

  end

  class YamlConfiguration

    attr_accessor :datashift_defaults, :datashift_populators

    include DataShift::Logging

    # N.B @mappings is an OpenStruct data structure
    #
    attr_reader :key
    attr_accessor :yaml_data, :key_config

    def initialize( key = nil)
      @key = key

      @config = OpenStruct.new
    end

    def read( file, key = nil )

      unless File.exist?(file)
        logger.error "Cannot open configuration file - #{file} - file does not exist."
        raise FileNotFound.new("Cannot open mapping file - #{file}")
      end

      begin
        # Load application configuration
        set_mapping( file )

        set_key_config!( key ) if key
      rescue => e
        logger.error e.inspect
        logger.error "Failed to parse config file #{map_file_name} - bad YAML ?"
        raise e
      end
    end

    # OpenStruct not a hash .. supports form ... config.path, config.full_name etc
    def method_missing(method, *_args, &_block)
      @config.send(method)
    end

    # Config file can contain sets of entries, identified with a key.
    # e.g
    #     A:
    #       log_level: 1
    #     B:
    #       log_level: 2
    #
    # Restrict searches/config entries to single set via key e.g 'A'
    #
    def set_key_config!( key )
      raise MissingConfigOptionError.new("No config entry found for key [#{key}]") unless yaml_data && yaml_data[key].is_a?(Hash)
      @key_config = OpenStruct.new( yaml_config[key] ) # Argument HAS to be a hash
    end

    # Merge another YAML section (identified by key) into @key_config
    def merge_key_config!( key )
      raise Beeline::MissingConfigOptionError.new("No config entry found for key [#{key}]") unless yaml_data && yaml_data[key].is_a?(Hash)

      temp = yaml_data[key].merge(@key_config.instance_variable_get('@table') || {})

      key_config = OpenStruct.new(temp)
    end

    def set( key, value)
      key_config.instance_variable_get('@table')[key] = value
    end

    private

    def set_mapping( file )

      erb = begin
        Erubis::Eruby.new( File.read(file )).result
      rescue => e
        logger.error "Failed to parse erb template #{file} error: #{e.inspect}"
        raise e
      end

      begin
        yaml_data = YAML.load(erb)

        logger.info "Loaded YAML config from [#{file}]"

      rescue => e
        logger.error "YAML parse error: #{e.inspect}"
        raise e
      end

      @config = OpenStruct.new(yaml_data)
    end

  end

end
