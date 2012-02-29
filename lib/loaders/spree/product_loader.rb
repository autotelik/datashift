# Copyright:: (c) Autotelik Media Ltd 2010
# Author ::   Tom Statter
# Date ::     Aug 2010
# License::   MIT ?
#
# Details::   Specific over-rides/additions to support Spree Products
#
require 'loader_base'
require 'csv_loader'
require 'excel_loader'
require 'image_loader'

module DataShift

  module Spree

    class ProductLoader < LoaderBase

      include DataShift::CsvLoading
      include DataShift::ExcelLoading
      include DataShift::ImageLoading

      def initialize(product = nil)
        super( Product, product, :instance_methods => true  )
        raise "Failed to create Product for loading" unless @load_object
      end

      # Based on filename call appropriate loading function
      # Currently supports :
      #   Excel/Open Office files saved as .xls
      #   CSV files
      def perform_load( file_name, options = {} )

        ext = File.extname(file_name)
          
        if(ext == '.xls')
          raise DataShift::BadRuby, "Please install and use JRuby for loading .xls files" unless(Guards::jruby?)
          perform_excel_load(file_name, options)
        elsif(ext == '.csv')
          perform_csv_load(file_name, options)
        else
          raise DataShift::UnsupportedFileType, "#{ext} files not supported - Try CSV or OpenOffice/Excel .xls"
        end
      end
      
      # Over ride base class process with some Spree::Product specifics
      #
      # What process a value string from a column, assigning value(s) to correct association on Product.
      # Method map represents a column from a file and it's correlated Product association.
      # Value string which may contain multiple values for a collection (has_many) association.
      #
      def process()

        # Special cases for Products, generally where a simple one stage lookup won't suffice
        # otherwise simply use default processing from base class
        if((@current_method_detail.operator?('variants') || @current_method_detail.operator?('option_types')) && current_value)

          add_options

        elsif(@current_method_detail.operator?('taxons') && current_value)

          add_taxons

        elsif(@current_method_detail.operator?('product_properties') && current_value)

          add_properties

        elsif(@current_method_detail.operator?('images') && current_value)

          add_images
          
        elsif(@current_method_detail.operator?('count_on_hand') || @current_method_detail.operator?('on_hand') )

          # Unless we can save here, in danger of count_on_hand getting wiped out.
          # If we set (on_hand or count_on_hand) on an unsaved object, during next subsequent save
          # looks like some validation code or something calls Variant.on_hand= with 0
          # If we save first, then our values seem to stick

          # TODO smart column ordering to ensure always valid - if we always make it very last column might not get wiped ?
          # 
          save_if_new
         
          # Spree has some stock management stuff going on, so dont usually assign to column vut use
          # on_hand and on_hand=
          if(@load_object.variants.size > 0 && current_value.include?(LoaderBase::multi_assoc_delim))

            #puts "DEBUG: COUNT_ON_HAND PER VARIANT",current_value.is_a?(String),
              #&& current_value.is_a?(String) && current_value.include?(LoaderBase::multi_assoc_delim))
            # Check if we processed Option Types and assign count per option
            values = current_value.to_s.split(LoaderBase::multi_assoc_delim)

            if(@load_object.variants.size == values.size)
              @load_object.variants.each_with_index {|v, i| v.on_hand = values[i]; v.save; }
            else
              puts "WARNING: Count on hand entries did not match number of Variants - None Set"
            end
          else
            #puts "DEBUG: COUNT_ON_HAND #{current_value.to_i}"
            load_object.on_hand = current_value.to_i
          end

        else
          super
        end
      end

      private

      # Special case for OptionTypes as it's two stage process
      # First add the possible option_types to Product, then we are able
      # to define Variants on those options values.
      #
      def add_options
        # TODO smart column ordering to ensure always valid by time we get to associations
        save_if_new

        option_types = current_value.split( LoaderBase::multi_assoc_delim )

        option_types.each do |ostr|
          oname, value_str = ostr.split(LoaderBase::name_value_delim)

          option_type = OptionType.find_by_name(oname)

          unless option_type
            option_type = OptionType.create( :name => oname, :presentation => oname.humanize)
            # TODO - dynamic creation should be an option

            unless option_type
              puts "WARNING: OptionType #{oname} NOT found - Not set Product"
              next
            end
          end

          @load_object.option_types << option_type unless @load_object.option_types.include?(option_type)

          # Can be simply list of OptionTypes, some or all without values
          next unless(value_str)

          # Now get the value(s) for the option e.g red,blue,green for OptType 'colour'
          ovalues = value_str.split(',')

          ovalues.each_with_index do |ovname, i|
            ovname.strip!
            ov = OptionValue.find_or_create_by_name(ovname)
            if ov
              object = Variant.create( :product => @load_object, :sku => "#{@load_object.sku}_#{i}", :price => @load_object.price, :available_on => @load_object.available_on)
              #puts "DEBUG: Create New Variant: #{object.inspect}"
              object.option_values << ov
              #@load_object.variants << object
            else
              puts "WARNING: Option #{ovname} NOT FOUND - No Variant created"
            end
          end
        end

      end

      # Special case for Images
      # A list of paths to Images with a optional 'alt' value - supplied in form :
      #   path:alt|path2:alt2|path_3:alt3 etc
      #
      def add_images
        # TODO smart column ordering to ensure always valid by time we get to associations
        save_if_new

        images = current_value.split(LoaderBase::multi_assoc_delim)

        images.each do |image|
          
          img_path, alt_text = image.split(LoaderBase::name_value_delim)
          
          image = create_image(img_path, @load_object, :alt => alt_text)
        end
      
      end

      
      # Special case for ProductProperties since it can have additional value applied.
      # A list of Properties with a optional Value - supplied in form :
      #   property.name:value|property.name|property.name:value
      #
      def add_properties
        # TODO smart column ordering to ensure always valid by time we get to associations
        save_if_new

        property_list = current_value.split(LoaderBase::multi_assoc_delim)

        property_list.each do |pstr|
          pname, pvalue = pstr.split(LoaderBase::name_value_delim)
          property = Property.find_by_name(pname)

          unless property
            property = Property.create( :name => pname, :presentation => pname.humanize)
          end

          if(property)
            @load_object.product_properties << ProductProperty.create( :property => property, :value => pvalue)
          else
            puts "WARNING: Property #{pname} NOT found - Not set Product"
          end
         
        end
      
      end

      
      def add_taxons
        # TODO smart column ordering to ensure always valid by time we get to associations
        save_if_new

        name_list = current_value.split(LoaderBase::multi_assoc_delim)

        taxons = name_list.collect do |t|

          taxon = Taxon.find_by_name(t)

          unless taxon
            parent = Taxonomy.find_by_name(t)

            begin
              if(parent)
                # not sure this can happen but just incase we get a weird situation where we have
                # a taxonomy without a root named the same - create the child taxon we require
                taxon = Taxon.create(:name => t, :taxonomy_id => parent.id)
              else
                parent = Taxonomy.create!( :name => t )

                taxon = parent.root
              end

            rescue => e
              e.backtrace
              e.inspect
              puts "ERROR : Cannot assign Taxon ['#{t}'] to Product ['#{load_object.name}']"
              next
            end
          end
          taxon
        end

        taxons.compact!

        @load_object.taxons << taxons unless(taxons.empty?)

      end

    end
  end
end