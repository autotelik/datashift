# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Read mappings and provide cache type services for source=>destination mappings
#
require 'erubis'

module DataShift

  module Importers

    class Configuration < DataShift::Configuration

      # List of headers/columns that are Mandatory i.e must be present in the inbound data
      #
      # @param [Array<#call>] List of headers/columns that are Mandatory
      # @return [Array<#call>]
      #
      attr_accessor :mandatory

      # @param [Boolean] Stop processing and abort if a row fails to import
      # Default is false
      # @return [Boolean]
      #
      attr_accessor :abort_on_failure
      
      def initialize
        @mandatory = []
        @abort_on_failure = false
      end

      # @return [DataShift::Importers::Configuration] DataShift's current configuration
      def self.call
        @configuration ||= Importers::Configuration.new
      end

      def self.reset
        @configuration = Importers::Configuration.new
      end

      # Set DataShift's configure
      # @param config [DataShift::Importers::Configuration]
      class << self
        attr_writer :configuration
      end

      # Modify DataShift's current Import configuration
      # ```
      # DataShift::Importers::Configuration.configure do |config|
      #   config.verbose = false
      # end
      # ```
      def self.configure
        yield call
      end

      # Modify DataShift's current Import configuration from an options hash

      def self.from_hash( options )
        DataShift::Importers::Configuration.configure do |config|
          config.mandatory = options[:mandatory] if(options[:mandatory])
        end
      end

    end
  end

end
