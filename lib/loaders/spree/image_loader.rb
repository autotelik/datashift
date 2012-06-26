# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT. Free, Open Source.
#
require 'loader_base'
require 'paperclip/image_loader'

module DataShift


  module DataShift::SpreeImageLoading
 
    include DataShift::Logging
    include DataShift::ImageLoading
     
    # Note the Spree Image model sets default storage path to
    # => :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

    def create_image(klass, attachment_path, viewable_record = nil, options = {})
        
      viewable =  (SpreeHelper::version.to_f > 1 && viewable_record.is_a?(Spree::Product) ) ? viewable_record.master : viewable_record
      
      super(klass, attachment_path, viewable, options)
    end
  end

  module SpreeHelper
     
    # TODO - extract this out of SpreeHelper to create  a general paperclip loader
    class ImageLoader < LoaderBase

      include DataShift::SpreeImageLoading
      include DataShift::CsvLoading
      include DataShift::ExcelLoading
      
      def initialize(image = nil, options = {})
        super( SpreeHelper::get_spree_class('Image'), image, options )
        
        if(SpreeHelper::version.to_f > 1.0 )
          @attachment_klazz  = DataShift::SpreeHelper::get_spree_class('Variant' )
        else
          @attachment_klazz  = DataShift::SpreeHelper::get_spree_class('Product' )
        end
        
        puts "Attachment Class is #{@attachment_klazz}" if(@verbose)
          
        raise "Failed to create Image for loading" unless @load_object
      end
      
      def process()

        if(current_value && @current_method_detail.operator?('attachment') )
          
          # assign the image file data as an attachment
          @load_object.attachment = get_file(current_value)
          
          puts "Image attachment created : #{@load_object.inspect}"
              
        elsif(current_value && @current_method_detail.operator )    
          
          # find the db record to assign our Image to
          add_record( get_record_by(@attachment_klazz, @current_method_detail.operator, current_value) )
                
        end
          
      end
    
      def add_record(record)
        if(record)
          if(SpreeHelper::version.to_f > 1 )
            @load_object.viewable = record
          else
            @load_object.viewable = record.product   # SKU stored on Variant but we want it's master Product
          end
          @load_object.save
          puts "Image viewable set : #{record.inspect}"
          
        else
          puts "WARNING - Cannot set viewable - No matching record supplied"
          logger.error"Failed to find a matching record"
        end
      end
    end
          
  end
end