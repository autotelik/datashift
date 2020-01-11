# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   Class to manage the removal of unwanted columns or data
#

module DataShift

  module Transformation

    class RemoveUnwantedHeaders
      def self.call(headers, config: DataShift::Configuration.call)
        Remove.new(config: config).unwanted_headers(headers)
      end
    end

    class Remove

      def initialize(config: DataShift::Configuration.call)
        @config = config
      end

      def remove_list
        @remove_list ||= @config.prep_remove_list
      end

      def association?(mm)
        return false unless(mm.association_type?)
        (@config.exclude_associations & [mm.operator, mm.operator.to_sym]).present?
      end

      # Specify columns to remove via DataShift::Configuration
      #
      def unwanted_columns( columns )
        columns.delete_if { |r| remove_list.include?( r.to_sym ) } unless remove_list.empty?
      end

      def unwanted_headers( headers )
        headers.delete_if { |r| remove_list.include?( r.source.to_sym ) } unless remove_list.empty?
      end

      # Specify columns to remove via DataShift::Configuration
      #
      def unwanted_model_methods( model_methods )
        model_methods.delete_if { |r| remove_list.include?( r.operator.to_sym ) } unless remove_list.empty?
      end

    end

  end

end
