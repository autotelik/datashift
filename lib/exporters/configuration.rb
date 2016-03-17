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

      # List of association +TYPES+ to INCLUDE (:belongs_to, :has_one etc)
      #
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
        @with = []
        @exclude = []
        @remove = []
        @remove_rails = true
        @sheet_name = ""
        @json = false
      end

      # @return [DataShift::Configuration] DataShift's current configuration
      def self.configuration
        @configuration ||= Exporters::Configuration.new
      end

      # Set DataShift's configuration
      # @param config [DataShift::Exporters::Configuration]
      class << self
        attr_writer :configuration
      end

      # Modify DataShift's current Export configuration
      # ```
      # DataShift::Exporters.configure do |config|
      #   config.verbose = false
      # end
      # ```
      def self.configure
        yield configuration
      end
    end


    end

  end
