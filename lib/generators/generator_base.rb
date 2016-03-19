# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# License::   MIT
#
# Details::  Base class for generators, which provide services to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    attr_accessor :headers, :remove_list

    attr_accessor :configuration

    def initialize
      @headers = DataShift::Headers.new(:na)
      @remove_list = []

      @configuration = DataShift::Exporters::Configuration.configuration
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

      # default to generating just klass columns
      associations = configuration.op_types_in_scope

      puts "DEBUG: Running klass_to_headers for Assocs : #{associations}"

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

        remove_headers
      end

      headers
    end

    alias :klass_to_collection_and_headers :klass_to_headers

    # Prepare to generate with associations but then
    # calls a **derived generate** method i.e abstract to this base class
    #
    # file_name => Filename for generated template
    #
    def generate_with_associations(file_name, klass, options = {})
      generate(file_name, klass, options)
    end


    # Parse options and remove  headers
    # Specify columns to remove via  lib/exporters/configuration.rb
    #
    def remove_headers
      remove_list = configuration.prep_remove_list

      headers.delete_if { |h| remove_list.include?( h.to_sym ) } unless remove_list.empty?
    end


  end

end
