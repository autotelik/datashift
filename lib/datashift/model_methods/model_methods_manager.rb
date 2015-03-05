# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Just a high level helper to Map Class => Collections of model methods
#
#
module DataShift

  module ModelMethods

    class Manager

      def self.collections
        collections ||= {}
      end

      def self.for(klass)
        collections[klass]
      end

      def self.for?(klass)
        collections[klass] != nil
      end

      # Build a thorough and usable picture of the operators which can be
      # used to import/export data to objects of type 'klass'
      #  Stored as a dictionary of ModelMethods objects
      #
      # Subsequent calls with same class will return existing mapping
      # To over ride this behaviour, supply
      #   :force => true to force  regeneration

      def self.catalog_class( klass, options = {} )

        return collections[klass] if(collections[klass] && !options[:force])

        ModelMethods::Catalogue.find_methods(klass) unless ModelMethods::Catalogue.catalogued?(klass)

        puts "DEBUG: build_for_klass : #{klass}"

        collection = ModelMethods::Collection.new( klass )

        DataShift::ModelMethods::Catalogue.assignments_for(klass).each do |n|
          collection <<  ModelMethod.new(klass, n, :assignment)
        end

        DataShift::ModelMethods::Catalogue.has_one_for(klass).each do |n|
          collection <<  ModelMethod.new(klass, n, :has_one)
        end

        DataShift::ModelMethods::Catalogue.has_many_for(klass).each do |n|
          collection <<  ModelMethod.new(klass, n, :has_many)
        end

        DataShift::ModelMethods::Catalogue.belongs_to_for(klass).each do |n|
          collection <<  ModelMethod.new(klass, n, :belongs_to)
        end

        collections[klass] = collection

        collection

      end

      def self.clear
        collections.clear
      end

    end

  end
end