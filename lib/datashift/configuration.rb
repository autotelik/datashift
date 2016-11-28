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
    # To raise an error instead, set this to  true
    # Defaults to `false`.
    # @param [Boolean] value
    # @return [Boolean]
    attr_accessor :strict_inbound_mapping

    # When performing writes use update methods that write immediately to DB
    # and use validations.
    #
    # Validations can ensure business logic, but can be less efficient as writes to DB once per column
    #
    # Default  is to use more efficient but less strict attribute writing - no write to DB/No validations run
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

    #  A directory path to be used to prefix all inbound PATHs
    #
    # @param [Path]
    # @return [Path]
    #
    attr_accessor :image_path_prefix

    def self.rails_columns
      @rails_standard_columns ||= [:id, :created_at, :created_on, :updated_at, :updated_on]
    end

    def initialize
      @with = [:assignment, :enum]
      @exclude = []
      @remove_columns = []

      @mandatory = []

      @strict_inbound_mapping = false
      @verbose = false
      @dummy_run = false
      @force_inclusion_of_columns = []
      @exclude_associations = []

      @expand_associations = false

      # default to more efficient attribute writing - no write to DB/no validations run
      @update_and_validate = false

      @image_path_prefix = nil
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

end
