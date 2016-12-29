# Copyright:: (c) Autotelik Media Ltd 2016
# Author ::   Tom Statter
# Date ::     March 2016
# License::   MIT
#
# Details::   Brute force case for assignments without a column type (which enables us to do correct type_cast)
#             so in this case, attempt straightforward assignment
#             then if that fails, try converting the inbound data via basic ops such as to_s, to_i, to_f etc
#
#             Enables users to assign values to AR object, without knowing much about that receiving object.
#
module DataShift

  module Populators

    class InsistentAssignment

      include DataShift::Logging
      extend DataShift::Logging

      def self.insistent_method_list
        @insistent_method_list ||= [:to_s, :downcase, :to_i, :to_f, :to_b]
      end

      # When looking up an association, when no field provided, try each of these in turn till a match
      # i.e find_by_name, find_by_title, find_by_id
      def self.insistent_find_by_list
        @insistent_find_by_list ||= [:name, :title, :id]
      end

      def self.call(record, value, operator)

        logger.debug("Attempting Brute force assignment of value #{value} => [#{operator}]")

        return if(attempt(record, value, operator))

        method_list = [operator]

        unless operator.include?('=')
          op = operator + '='

          return if(attempt(record, value, op))
          return if(attempt(record, value, op.downcase))

          method_list += [op,  op.downcase]
        end

        method_list.each do |method|
          InsistentAssignment.insistent_method_list.each do |f|
            begin
              return if(attempt(record, value.send(f), method))
            rescue
            end
          end
        end

        raise DataProcessingError, "Failed to assign [#{value}] to #{operator}" unless value.nil?

      end

      class << self
        private

        def attempt(record, value, operator)
          begin
            record.send(operator, value)
          rescue
            logger.debug("Brute forced failed for [#{operator}, #{value}]")
            return false
          end
          logger.debug("Brute forced success using [#{operator}]")
          true
        end
      end

    end

  end
end
