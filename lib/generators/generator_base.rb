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
    def to_headers(klass, options = {})

      # default to generating just klass columns
      associations = options[:with] || [:assignment]

      @headers = Headers.new(klass)

      collection = ModelMethods::Manager.catalog_class(klass)

      associations.each do |a|
        collection.for_type(a).each { |md| @headers << "#{md.operator}" }
      end if(collection)

      remove_headers(options)

      headers
    end

    alias_method :collection_to_headers, :to_headers

    # Create CSV file representing supplied Model
    #
    # Options
    # [:filename] => Filename for generated template
    #
    # [:with] => List of association Types to include (:has_one etc)
    #
    #   Otherwise, defaults to including all association types defined by
    #   ModelMethod.supported_types_enum - which can be further refined by
    #
    # [:exclude] => List of association Types to include (:has_one etc)
    #
    # [:remove] => List of headers to remove from generated template
    #
    # [:remove_rails] => Remove standard Rails cols like :id, created_at etc
    #
    def generate_with_associations(klass, options = {})
      options[:with] = op_types_in_scope(options)

      generate(klass, options)
    end

    # Prepare the operators types in scope based on options
    #
    def op_types_in_scope( options = {} )
      options[:with] || ModelMethod.supported_types_enum - [ *options[:exclude] ]
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
      headers.delete_if { |h| remove_list.include?( h.to_sym ) } unless(remove_list.empty?)
    end

    protected

    # Take options and create a list of symbols to remove from headers
    #
    # Rails columns like id, created_at etc are included by default
    # Specify option :remove_rails to remove them from output
    #
    def prep_remove_list( options )
      @remove_list = [ *options[:remove] ].compact.collect { |x| x.to_s.downcase.to_sym }

      @remove_list += GeneratorBase.rails_columns if(options[:remove_rails])

      remove_list
    end



  end

end
