# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT
#
#  Details::  Base class for loaders, providing a process hook which populates a model,
#             based on a method map and supplied value from a file - i.e a single column/row's string value.
#             Note that although a single column, the string can be formatted to contain multiple values.
#
#             Tightly coupled with Binder classes (in lib/engine) which contains full details of
#             a file's column and it's correlated AR associations.
#
module DataShift

  require 'datashift/binder'

  module  Querying

    # Return arrays 'where' clause field(s), and the value(s) to search for
    #
    # If not contained within inbound_data, check the Inbound Column headings
    # .
    # Where field embedded in row ,takes precedence over field in column heading
    #
    # Treat rest of the node as the value to use in the where clause e.g
    #   price:0.99 =>  Product.where( price: 0.99)
    #
    # Column headings will be used, if the row only contains data e.g
    #   0.99
    #
    def self.where_field_and_values(method_binding, inbound_data)

      part1, part2 = inbound_data.split(Delimiters::name_value_delim)

      heading_lookups = method_binding.inbound_column.lookup_list

      if((part1.nil? || part1.empty?) && (part2.nil? || part2.empty?))

        # Column completely empty - check for lookup supplied via the
        # inbound column headers/config

        #TODO - how best to support multipel lookup fields?
        # part1 = heading_lookups.collect {|lookup| lookup.field }
        part1 = heading_lookups.find_by_operator
        part2 = heading_lookups.collect {|lookup| lookup.value }

      elsif((part2.nil? || part2.empty?))

        # Only **value(s)** in column, so use field from header/config field

        puts("DEBUG: No part2e [#{part1}][#{part1.class}] - [#{part2}][#{part2.class}]")

        part2 = part1.split(Delimiters::multi_value_delim)
        part1 = method_binding.inbound_column.find_by_operator

      else
        part2 = part2.split(Delimiters::multi_value_delim)

      end

      puts("DEBUG: Where clause [#{part1}][#{part1.class}] - [#{part2}][#{part2.class}]")

      return part1, [*part2]
    end

    # Options:
    #
    #   :case_sensitive   : Default is a case insensitive lookup.
    #   :use_like         : Attempts a lookup using ike and x% rather than equality
    #
    def search_for_record(klazz, field, search_term, options = {})

      begin

        if(options[:case_sensitive])
          return klazz.send("find_by_#{field}", search_term)
        elsif(options[:use_like])
          return klazz.where("#{field} like ?", "#{search_term}%").first
        else
          return klazz.where("lower(#{field}) = ?", search_term.downcase).first
        end

      rescue => e
        puts e.inspect
        logger.error("Exception attempting to find a record for [#{search_term}] on #{klazz}.#{field}")
        logger.error e.backtrace
        logger.error e.inspect
      end

      nil
    end

    # Find a record for model klazz, looking up on field containing search_terms
    # Responds to global Options :
    #
    #   :add_prefix     : Add a prefix to each search term
    #   :case_sensitive : Default is a case insensitive lookup.
    #   :use_like       : Attempts a lookup using like and x% rather than equality
    #
    # Returns nil if no record found
    def get_record_by(klazz, field, search_term, split_on = ' ', options = {})

      begin

        split_on_prefix = options[:add_prefix]

        z = (split_on_prefix) ? "#{split_on_prefix}#{search_term}": search_term

        logger.info("Scanning for record where #{klazz}.#{field} ~=  #{z}")

        record = search_for_record(klazz, field, z)

        # try individual portions of search_term, front -> back i.e "A_B_C_D" => A, B, C etc
        search_term.split(split_on).each do |str|
          z = (split_on_prefix) ? "#{split_on_prefix}#{str}": str
          record = search_for_record(klazz, field, z, options)
          break if record
        end unless(record)

        # this time try incrementally scanning i.e "A_B_C_D" => A, A_B, A_B_C etc
        search_term.split(split_on).inject("") do |str, term|
          z = (split_on_prefix) ? "#{split_on_prefix}#{str}#{split_on}#{term}": "#{str}#{split_on}#{term}"
          record = search_for_record(klazz, field, z, options)
          break if record
          term
        end unless(record)

        if(record && record.respond_to?(field))
          logger.info("Record found for #{klazz}.#{field} : #{record.send(field)}" )
        end

        return record
      rescue => e
        logger.error("Exception attempting to find a record for [#{search_term}] on #{klazz}.#{field}")
        logger.error e.backtrace
        logger.error e.inspect
        return nil
      end
    end

    def get_record_by!(klazz, field, search_terms, split_on = ' ', options = {} )
      x = get_record_by(klazz, field, search_terms, split_on, options)

      raise RecordNotFound, "No #{klazz} record found for [#{search_terms}] on #{field}" unless(x)

      x
    end
  end

end