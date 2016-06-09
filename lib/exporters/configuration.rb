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

    class Configuration < Configuration

      # @param [Char] Char to use as the column delimter for csv format
      # @return [Char]
      #
      attr_accessor :csv_delimiter

      # @param [Boolean] Export association data in single column in JSON format
      # @return [Boolean]
      #
      attr_accessor :json


      # @param [String] Name for worksheet, otherwise uses Class name
      # @return [String]
      #
      attr_accessor :sheet_name

      # @param [Boolean] Stop processing and abort if a row fails to export
      # Default is false
      # @return [Boolean]
      #
      attr_accessor :abort_on_failure

      def initialize
        super
        @remove_rails = false
        @sheet_name = ''
        @json = false
        @csv_delimiter = ','
        @abort_on_failure = false
      end

      # @return [DataShift::Exporters::Configuration] DataShift's current configuration
      def self.call
        @configuration ||= Exporters::Configuration.new
      end

      def self.reset
        @configuration = Exporters::Configuration.new
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
        yield call
      end

      # Modify DataShift's current Export configuration from an options hash

      def self.from_hash( options )

        DataShift::Configuration.from_hash(options)

        DataShift::Exporters::Configuration.configure do |config|

          config.with = [:all] if(options[:associations])

          config.remove_rails = true if(options[:remove_rails])

          # TODO: DRY by processing all simple assignments as a list
          config.with = options[:with] if(options[:with])
          config.exclude = options[:exclude] if(options[:exclude])
          config.remove = options[:remove] if(options[:remove])
          config.csv_delimiter = options[:csv_delimiter] if(options[:csv_delimiter])
        end
      end



    end
  end

end
