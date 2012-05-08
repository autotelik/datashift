# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT. Free, Open Source.
#
require 'loader_base'

module DataShift


  module ImageLoading
 
    include DataShift::Logging
     
    # Note the Spree Image model sets default storage path to
    # => :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

    def create_image(klass, image_path, viewable_record = nil, options = {})
       
      unless File.exists?(image_path) && File.readable?(image_path)
        logger.error("Cannot process Image from #{Dir.pwd}: Invalid Path #{image_path}")
        raise "Cannot process Image : Invalid Path #{image_path}"
      end
      
      alt = if(options[:alt])
        options[:alt]
      else
        (viewable_record and viewable_record.respond_to? :name) ? viewable_record.name : ""
      end
     
      file = begin
        File.new(image_path, "rb")
      rescue => e
        puts e.inspect
        raise "ERROR : Failed to read image #{image_path}"
      end

      position = (viewable_record and viewable_record.respond_to?(:images)) ? viewable_record.images.length : 0
      
      image = klass.new( :attachment => file,:viewable => viewable_record, :alt => alt, :position => position)  
      #image.attachment.reprocess!
   
      #image.viewable =  viewable_record if viewable_record

      puts image.save ? "Success: Created Image: #{image.inspect}" : "ERROR : Problem saving to DB Image: #{image.inspect}"
    end
  end

  module SpreeHelper
       
    class ImageLoader < LoaderBase

      include DataShift::ImageLoading
      include DataShift::CsvLoading
      include DataShift::ExcelLoading
      
      def initialize(image = nil)
        puts SpreeHelper::get_spree_class('Image')
        
        @@image_klass ||= SpreeHelper::get_spree_class('Image')
            
        super( @@image_klass, image )
        raise "Failed to create Image for loading" unless @load_object
      end

      # The path to the physical image on local disk
      def process(image_path, record = nil)
        @load_object = create_image(@@image_klass, image_path, record)
      end
    end
  end
end