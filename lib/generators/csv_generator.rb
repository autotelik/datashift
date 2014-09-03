# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2011
# License::   MIT
#
# Details::   Export a model to CSV
#
#
require 'generator_base'

module DataShift

  class CsvGenerator < GeneratorBase

    include DataShift::Logging

    def initialize(filename)
      super(filename)
    end

    # Create CSV file representing supplied Model

    def generate(klass, options = {})
      @filename = options[:filename] if options[:filename]

      prep_remove_list(options)

      MethodDictionary.find_operators( klass )
      @headers = MethodDictionary.assignments[klass]

      @headers.delete_if{|h| @remove_list.include?( h.to_sym ) }

      logger.info("CSVGenerator saving generated template #{@filename}")

      CSV.open(@filename, "w") do |csv|
        csv << @headers
      end
    end

    def generate_with_associations(klass, options = {})
      @filename = options[:filename] if options[:filename]

      MethodDictionary.find_operators( klass )
      MethodDictionary.build_method_details( klass )

      work_list = MethodDetail::supported_types_enum.to_a - [ *options[:exclude] ]

      prep_remove_list(options)

      @headers = []

      details_mgr = MethodDictionary.method_details_mgrs[klass]

      work_list.each do |assoc_type|
        method_details_for_assoc_type = details_mgr.get_list_of_method_details(assoc_type)

        next if(method_details_for_assoc_type.nil? || method_details_for_assoc_type.empty?)

        method_details_for_assoc_type.each do |md|
          comparable_association = md.operator.to_s.downcase.to_sym

          i = remove_list.index { |r| r == comparable_association }

          (i) ? remove_list.delete_at(i) : headers << "#{md.operator}"
        end
      end

      logger.info("CSVGenerator saving generated with associations template #{@filename}")

      CSV.open(@filename, "w") do |csv|
        csv << @headers
      end
    end


    # Create an CSV file representing supplied Model

    def export(items, options = {})
    end


    private

    # Take options and create a list of symbols to remove from headers
    #
    def prep_remove_list( options )
      @remove_list = [ *options[:remove] ].compact.collect{|x| x.to_s.downcase.to_sym }

      @remove_list += GeneratorBase::rails_columns if(options[:remove_rails])
    end

  end
end
