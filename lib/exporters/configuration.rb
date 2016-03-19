# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Read mappings and provide cache type services for source=>destination mappings
#
require 'erubis'

module DataShift

  module Exporters

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

      # @param [Array<#call>] List of columns to remove from exported files
      # @return [Array<#call>]
      #
      attr_accessor :remove

      # @param [Boolean] Remove standard Rails cols like :id, created_at etc
      # @return [Boolean]
      #
      attr_accessor :remove_rails

      # @param [String] Name for worksheet, otherwise uses Class name
      # @return [String]
      #
      attr_accessor :sheet_name

      # @param [Boolean] Export association data in single column in JSON format
      # @return [Boolean]
      #
      attr_accessor :json


      def initialize
        @with = [:assignment, :enum]
        @exclude = []
        @remove = []
        @remove_rails = true
        @sheet_name = ""
        @json = false
      end

      # @return [DataShift::Exporters::Configuration] DataShift's current configuration
      def self.configuration
        @configuration ||= Exporters::Configuration.new
      end

      # Set DataShift's configure
      # @param config [DataShift::Exporters::Configuration]
      class << self
        attr_writer :configuration
      end

      # Modify DataShift's current Export configuration
      # ```
      # DataShift::Exporters::Configuration.configure do |config|
      #   config.verbose = false
      # end
      # ```
      def self.configure
        yield configuration
      end

      # Prepare the operators types in scope based on options
      # Default is assignment only
      #
      # Options
      #   with: [:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
      #
      #   with: :all -> all op types
      #
      #   exclude: - Remove any of [::assignment, :enum, :belongs_to, :has_one, :has_many, :method]
      #
      def op_types_in_scope

        types_in_scope = []

        puts "DEBUG: op_types_in_scope with #{@with} "
        types_in_scope =if(with_all?)
                          puts "DEBUG: op_types_in_scope with ALL #{@with} "
                          ModelMethod.supported_types_enum.dup
                        else
                          @with.dup
                        end

        types_in_scope -= @exclude

        puts "DEBUG: types_in_scope #{types_in_scope.inspect} "

        types_in_scope
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
        remove_list = [*@remove].compact.collect { |x| x.to_s.downcase.to_sym }

        remove_list += DataShift::Configuration.rails_columns if(remove_rails)

        remove_list
      end


    end
  end

end
