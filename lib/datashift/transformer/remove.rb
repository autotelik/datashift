# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     Feb 2016
# License::   MIT
#
# Details::   Class to manage the removal of unwanted columns or data
#

module DataShift

  module Transformer

    class Remove

      def self.remove_list
        DataShift::Exporters::Configuration.call.prep_remove_list
      end

      # Specify columns to remove via DataShift::Exporters::Configuration
      #
      def self.unwanted_columns( columns )
        remove_list = DataShift::Exporters::Configuration.call.prep_remove_list

        columns.delete_if { |r| remove_list.include?( r.to_sym ) } unless remove_list.empty?
      end

      # Specify columns to remove via DataShift::Exporters::Configuration
      #
      def self.unwanted_model_methods( model_methods )
        remove_list = DataShift::Exporters::Configuration.call.prep_remove_list

        model_methods.delete_if { |r| remove_list.include?( r.operator.to_sym ) } unless remove_list.empty?
      end


    end

  end

end
