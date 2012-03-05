# Copyright:: (c) Autotelik Media Ltd 2011
# Author ::   Tom Statter
# Date ::     Jan 2011
# License::   MIT. Free, Open Source.
#
require 'loader_base'

module DataShift

   module ImageLoading
 
    # Note the Spree Image model sets default storage path to
    # => :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

    def create_image(image_path, viewable_record = nil, options = {})

      @@image_klass ||= SpreeHelper::get_spree_class('Image')
      
      image = @@image_klass.new
      
      unless File.exists?(image_path)
        puts "ERROR : Invalid Path"
        return image
      end

      alt = if(options[:alt])
        options[:alt]
      else
        (viewable_record and viewable_record.respond_to? :name) ? viewable_record.name : ""
      end
      
      image.alt = alt

      begin
        image.attachment = File.new(image_path, "r")
      rescue => e
        puts e.inspect
        puts "ERROR : Failed to read image #{image_path}"
        return image
      end

      image.attachment.reprocess!
      image.viewable =  viewable_record if viewable_record

      puts image.save ? "Success: Created Image: #{image.inspect}" : "ERROR : Problem saving to DB Image: #{image.inspect}"
    end
  end
  
  class ImageLoader < LoaderBase

    include DataShift::ImageLoading
        
    def initialize(image = nil)
      @@image_klass ||= SpreeHelper::get_spree_class('Image')
            
      super( @@image_klass, image )
      raise "Failed to create Image for loading" unless @load_object
    end

    # Note the Spree Image model sets default storage path to
    # => :path => ":rails_root/public/assets/products/:id/:style/:basename.:extension"

    def process( image_path, record = nil)
      @load_object = create_image(path, record)
    end
  end

end