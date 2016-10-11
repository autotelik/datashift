# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
module DataShift

  class Mandatory

    include DataShift::Logging

    attr_reader :mandatory_columns, :missing_columns

    def initialize(columns)

      @mandatory_columns = [*columns]

      logger.info("Mandatory columns set to #{@mandatory_columns.inspect}") unless @mandatory_columns.empty?

      @comparable_mandatory_columns = @mandatory_columns.collect(&:downcase)
      @missing_columns = []
    end

    def empty?
      @comparable_mandatory_columns.empty?
    end

    # Sets mandatory_columns
    # Returns true if bound methods contain every method listed in Mandatory
    #
    def contains_all?( binder )
      return true if(empty?)
      @missing_columns = @comparable_mandatory_columns - binder.operator_names.collect(&:downcase)
      @missing_columns.empty?
    end

  end

end
