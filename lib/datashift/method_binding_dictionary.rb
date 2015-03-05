# Copyright:: (c) Autotelik Media Ltd 2012
# Author ::   Tom Statter
# Date ::     Aug 2015
# License::   MIT
#
# Details::   A cache type class that stores details of binding between inbound data
#             and its associated operations on a domain model
#
module DataShift

  class MethodBindingDictionary

    include DataShift::Logging
    extend DataShift::Logging
=begin
    # Return true if dictionary has  been populated for  klass
    def self.for?(klass)
      any = has_many[klass] || belongs_to[klass] || has_one[klass] || assignments[klass]
      return any != nil
    end

    def self.setters( klass )

      # N.B In 1.8 these return strings, in 1.9 symbols.
      # map everything to strings a
      #setters = klass.accessible_attributes.sort.collect( &:to_s )

      # remove methods that start with '_'
      @keep_only_pure_setters ||= Regexp.new(/^[a-zA-Z]\w+=/)

      setters = klass.instance_methods.grep(@keep_only_pure_setters).sort.collect( &:to_s )
      setters.uniq
    end

    def self.add( klass, operator, type = :assignment)
      method_details_mgr = get_method_details_mgr( klass )
      md = MethodDetail.new(klass, operator, type)
      method_details_mgr <<  md
      return md
    end
=end

    # TODO - check out regexp to do this work better plus Inflections ??
    # Want to be able to handle any of ["Count On hand", 'count_on_hand', "Count OnHand", "COUNT ONHand" etc]
    def self.substitutions(external_name)
      name = external_name.to_s

      [
          name.downcase,
          name.tableize,
          name.gsub(' ', '_'),
          name.gsub(' ', '_').downcase,
          name.gsub(/(\s+)/, '_').downcase,
          name.gsub(' ', ''),
          name.gsub(' ', '').downcase,
          name.gsub(' ', '_').underscore
      ]
    end

    # Assignments can contain things like delegated methods, this returns a matching
    # method details only when a true database column
    def self.find_method_detail_if_column( klass, external_name )

      method_details_mgr = get_method_details_mgr( klass )

      # first try for an exact match across all association types
      ModelMethod.supported_types_enum.each do |t|
        method_detail = method_details_mgr.find(external_name, t)
        return method_detail.clone if(method_detail && method_detail.col_type)
      end

      # Now try various alternatives
      substitutions(external_name).each do |n|
        # Try each association type, returning first that contains matching operator with name n
        ModelMethod.supported_types_enum.each do |t|
          method_detail = method_details_mgr.find(n, t)
          return method_detail.clone if(method_detail && method_detail.col_type)
        end
      end

      nil
    end


    def self.clear
      belongs_to.clear
      has_many.clear
      assignments.clear
      column_types.clear
      has_one.clear
      method_details_mgrs.clear
    end

    def self.column_key(klass, column)
      "#{klass.name}:#{column}"
    end

    def self.get_method_details_mgr( klass )
      method_details_mgrs[klass] || MethodDetailsManager.new( klass )
    end


  end

end