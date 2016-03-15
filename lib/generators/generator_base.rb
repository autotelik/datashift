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
    def klass_to_headers(klass, options = {})

      # default to generating just klass columns
      associations = if options[:with]
                       options[:with].dup
                     else
                       [:assignment]
                     end

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

    # Prepare the operators types in scope based on options
    # Default is assignment only
    #
    # Options
    #   with: [:assignment, :enum, :belongs_to, :has_one, :has_many, :method]
    #
    #   with: :all -> all op types
    #
    #   exclude: - Remove any of [::assignment, :enum, :belongs_to, :has_one, :has_many, :method]
    #
    def op_types_in_scope( options = {} )

      types_in_scope = []

      if options[:with].nil?
        types_in_scope << :assignment
      elsif options[:with] == :all
        types_in_scope += ModelMethod.supported_types_enum.to_a
      end

      types_in_scope -= [*options[:exclude]]

      types_in_scope
    end

    def self.rails_columns
      @rails_standard_columns ||= [:id, :created_at, :created_on, :updated_at, :updated_on]
    end

    # Parse options and remove  headers

    # Specify columns to remove with :
    #  Options:
    #     [:remove]
    #
    # Rails columns like id, created_at are removed by default,
    #  to keep them in specify
    #   options[:include_rails]
    #
    def remove_headers(options)
      remove_list = prep_remove_list( options )

      # TODO: - more efficient way ?

      # comparable_association = md.operator.to_s.downcase.to_sym
      # i = remove_list.index { |r| r == comparable_association }
      # (i) ? remove_list.delete_at(i) : @headers << "#{md.operator}"
      headers.delete_if { |h| remove_list.include?( h.to_sym ) } unless remove_list.empty?
    end

    protected

    # Take options and create a list of symbols to remove from headers
    #
    # Rails columns like id, created_at etc are included by default
    # Specify option :remove_rails to remove them from output
    #
    def prep_remove_list( options )
      @remove_list = [*options[:remove]].compact.collect { |x| x.to_s.downcase.to_sym }

      @remove_list += GeneratorBase.rails_columns if options[:remove_rails]

      remove_list
    end

  end

end
