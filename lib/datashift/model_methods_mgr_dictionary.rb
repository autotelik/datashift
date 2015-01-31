# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   Map classes => model method managers
#
#             class => [operators]
#

module DataShift

  module ModelMethods

    # Stores ModelMethods for a class mapped by type
    class ManagerDictionary

      def self.managers
        @model_method_mgrs ||= {}
      end

      def self.for(klass)
        managers[klass]
      end

      # Build a thorough and usable picture of the operators which can be
      # used to import/export data to objects of type 'klass'
      #  Stored as a dictionary of ModelMethods objects
      #
      # Subsequent calls with same class will return existing mapping
      # To over ride this behaviour, supply
      #   :force => true to force  regeneration

      def self.build_for_klass( klass, options = {} )

        return managers[klass] if(managers[klass] && !options[:force])

        DataShift::ModelMethods::Catalogue.find_methods(klass) unless DataShift::ModelMethods::Catalogue.methods_for?(klass)

        model_method_mgr = Manager.new( klass )

        DataShift::ModelMethods::Catalogue.assignments_for(klass).each do |n|
          model_method_mgr <<  ModelMethod.new(klass, n, :assignment)
        end

        DataShift::ModelMethods::Catalogue.has_one_for(klass).each do |n|
          model_method_mgr <<  ModelMethod.new(klass, n, :has_one)
        end

        DataShift::ModelMethods::Catalogue.has_many_for(klass).each do |n|
          model_method_mgr <<  ModelMethod.new(klass, n, :has_many)
        end

        DataShift::ModelMethods::Catalogue.belongs_to_for(klass).each do |n|
          model_method_mgr <<  ModelMethod.new(klass, n, :belongs_to)
        end

        managers[klass] = model_method_mgr

        model_method_mgr

      end

      def self.clear
        managers.clear
      end

    end

  end
end