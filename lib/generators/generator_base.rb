# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for generators, which provide serivrs to describe a Model in an external format
#
module DataShift

  class GeneratorBase

    attr_accessor :filename, :headers, :remove_list
  
    def initialize(filename)
      @filename = filename
      @headers = []
      @remove_list =[]
    end

    def self.rails_columns
      @rails_standard_columns ||= [:id, :created_at, :created_on, :updated_at, :updated_on]
    end

    # Parse options and remove  headers
    # Specify columns to remove with :
    #   options[:exclude]
    # Rails columns like id, created_at are removed by default,
    #  to keep them in specify
    #   options[:include_rails]
    #
    def remove_headers(options)
      remove_list = prep_remove_list( options )

      #TODO - more efficient way ?
      headers.delete_if { |h| remove_list.include?( h.to_sym ) } unless(remove_list.empty?)
    end


    # Take options and create a list of symbols to remove from headers
    # Rails columns like id, created_at etc are added to the remove list by default
    # Specify :include_rails to keep them in
    def prep_remove_list( options )
      remove_list = [ *options[:exclude] ].compact.collect{|x| x.to_s.downcase.to_sym }

      remove_list += GeneratorBase::rails_columns unless(options[:include_rails])

      remove_list
    end

  end

end