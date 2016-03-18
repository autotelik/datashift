# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  Base class for generators, which provide services to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    attr_accessor :headers, :remove_list

    def initialize
      @headers = DataShift::Headers.new(:na)
      @remove_list = []
    end

    # Helpers for dealing with Active Record models and collections
    # Catalogs the supplied Klass and builds set of expected/valid Headers for Klass
    #
    # Options:
    #
    # [:with] => [SYMBOLS]
    #     Specify array of operators/associations to include - possible values :
    #         [:assignment, :belongs_to, :has_one, :has_many]
    #
    # [:remove] - List of headers to remove from generated template
    #
    # [:remove_rails] - Remove standard Rails cols like id, created_at etc
    #
    def klass_to_headers(klass)

      configuration = DataShift::Exporters::Configuration.configuration

      # default to generating just klass columns
      associations = configuration.op_types_in_scope

      @headers = Headers.new(klass)

      collection = ModelMethods::Manager.catalog_class(klass)

      if collection

        # make sure models columns are first, then other association types
        if associations.delete(:assignment)
          collection.for_type(:assignment).each { |md| @headers << md.operator.to_s }
        end

        associations.each do |a|
          collection.for_type(a).each { |md| @headers << md.operator.to_s }
        end

        remove_headers(options)
      end

      headers
    end

    alias :klass_to_collection_and_headers :klass_to_headers

    # Prepare to generate with associations but then
    # calls a **derived generate** method i.e abstract to this base class
    #
    # file_name => Filename for generated template
    #
    # Options
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    #   DEFAULT : Include ALL association types defined by
    #   ModelMethod.supported_types_enum - which can be further refined by
    #
    # List can can be further refined by
    #
    # [:exclude] => List of association Types to exclude (:has_one etc)
    #
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def generate_with_associations(file_name, klass, options = {})

      # with_associations - so over ride to default to :all if nothing specified
      options[:with] = :all if options[:with].nil?

      # sort out exclude etc
      options[:with] = op_types_in_scope( options )

      generate(file_name, klass, options)
    end


    # Parse options and remove  headers
    # Specify columns to remove via  lib/exporters/configuration.rb
    #
    def remove_headers
      options = DataShift::Exporters::Configuration.configuration

      remove_list = options.prep_remove_list

      headers.delete_if { |h| remove_list.include?( h.to_sym ) } unless remove_list.empty?
    end


  end

end
