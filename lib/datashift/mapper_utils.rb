# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     Feb 2015
# License::   MIT
#
# Details::   Helpers for mapping to/from inbound data and Classes

module DataShift

  class MapperUtils

    def self.class_from_string_or_raise( klass )

      ruby_klass = begin
        # support modules e.g "Spree::Property")
        MapperUtils.class_from_string(klass)  # Kernel.const_get(model)
      rescue NameError => e
        puts e
        raise Thor::Error.new("ERROR: No such Class [#{klass}] found - check valid model supplied")
      end

      fail NoSuchClassError.new("ERROR: No such Model [#{klass}] found - check valid model supplied") unless(ruby_klass)

      ruby_klass
    end

    # Helper to deal with string versions of modules/namespaced classes
    # Find and return the base class from a string.
    #
    # e.g "Spree::Property" returns the Spree::Property class
    # Raises exception if no such class found
    def self.const_get_from_string(str)
      str.to_s.split('::').inject(Object) do |mod, class_name|
        mod.const_get(class_name)
      end
    end

    # Similar to const_get_from_string except this version
    # returns nil if no such class found
    # Support modules e.g "Spree::Property"
    #
    def self.class_from_string( str )

      MapperUtils.const_get_from_string(str.to_s)  # Kernel.const_get(model)
    rescue
      return nil

    end

  end
end
