# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   Class to manage the removal of unwanted columns or data
#

module DataShift

  module Transformation

    class Remove

      def remove_list
        @remove_list ||= DataShift::Configuration.call.prep_remove_list
      end

      def association?(mm)
        return false unless(mm.association_type?)
        DataShift::Configuration.call.exclude_associations.include?(mm.operator)
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
