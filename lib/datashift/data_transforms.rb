# Copyright:: (c) Autotelik Media Ltd 2015
# Author ::   Tom Statter
# Date ::     March 2015
# License::   MIT
#
# Details::   Stores defaults, substitutions, over rides etc
#             that can be applied to incoming data while being Populated
#
# WORK In PROGRESS

module DataShift

  module Transformations

    # Default values and over rides can be provided in Ruby/YAML ???? config file.
    #
    #  Format :
    #
    #    Load Class:    (e.g Spree:Product)
    #     datashift_defaults:
    #       value_as_string: "Default Project Value"
    #       category: reference:category_002
    #
    #     datashift_overrides:
    #       value_as_double: 99.23546
    #
    #
    #     datashift_substitutions:
    #
    #

    class Base

      include DataShift::Logging

      # Map a Column to all relevant transforms

      def configure_from(load_object_class, yaml_file)

        data = YAML::load( ERB.new( IO.read(yaml_file) ).result )

        if(data[load_object_class.name])
        end
      end

      # Set a value to be used to populate Model.operator
      # Generally over-rides will be used regardless of what value caller supplied.
      def set( operator, value )
        override_values[operator] = value
      end

      def transforms
        @transforms ||= {}
      end

      def apply( operator, current_value )
        if(transforms[operator])
          perform_transformcurrent_value()
        end
      end

      def has_transform?( operator )
        return override_values.has_key?(operator)
      end

    end

    class Substitution < Base

      def type
        :substitution
      end
    end

    class Override < Base

      def type
        :override
      end
    end

  end
end
